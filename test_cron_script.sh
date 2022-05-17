
CRON_ENABLE_FILTERING=1

if [ $CRON_ENABLE_FILTERING -gt 0 ]; then
   source ./cron_script.sh
else
   function prohibit_output()
   {
      echo "=> dummy is called"
      return 1
   }
fi

TEST_CASE=""
STATE_FILE="/tmp/${0}.cron"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

function debug()
{
   echo -e "${TEST_CASE} - ${1}"
}

function failed()
{
   debug "${RED}FAILED${NC}, ${1}"
   exit 1
}

function passed()
{
   debug "${GREEN}PASSED${NC}"
}

function _get_item_from_state_file()
{
   cat $STATE_FILE | cut -d ':' -f${1}
}

function get_periodicity()
{
   _get_item_from_state_file 3
}

function get_timestamp()
{
   _get_item_from_state_file 2
}

function get_state()
{
   _get_item_from_state_file 1
}

function test_case_01()
{
   # given there is no state file in temp, init command
   # creates one and set provided periodicity in seconds
   TEST_CASE=${FUNCNAME[0]}
   local PERIODICITY=2

   # setup
   rm -f $STATE_FILE

   # call UUT
   EXP_PERIODICITY=140
   prohibit_output "init" $EXP_PERIODICITY
   prohibit_output "ok"

   # assertions
   if ! [ -f ${STATE_FILE} ]; then
      failed "ERROR: we expected a state file in ${STATE_FILE}"
      return 0
   fi

   PERIODICITY=$(get_periodicity)
   if [[ ${PERIODICITY} != ${EXP_PERIODICITY} ]]; then
      failed "ERROR: we expected PERIODICITY: ${EXP_PERIODICITY}, got ${PERIODICITY}"
   fi

   EXP_STATE="OK"
   STATE=$(get_state)
   if ! [[ $STATE == $EXP_STATE ]]; then
      failed "expected state $EXP_STATE, received $STATE"
   fi

   passed
   unset TEST_CASE
   return 0
}

function test_case_02()
{
   # given an invalid command, function return 0
   TEST_CASE=${FUNCNAME[0]}

   # setup
   rm -f ${STATE_FILE}

   # call UUT
   prohibit_output "unknown command" &> /dev/null && failed ""

   passed
   unset TEST_CASE
   return 0
}

function test_case_03()
{
   # given 2 subsequent calls with OK, after state UNKNOWN
   # results in the first one return 0 and the second one return 1
   TEST_CASE=${FUNCNAME[0]}

   # setup
   rm -f ${STATE_FILE}

   # call UUT, first and second time
   prohibit_output "ok" && failed "expected 0 received 1"
   prohibit_output "ok" || failed "expected 1, received 0"

   passed
   unset TEST_CASE
   return 0
}

function test_case_04()
{
   # recovering from FAILED state, with single
   # message when transitioning to OK
   TEST_CASE=${FUNCNAME[0]}

   # setup
   # given the system being in FAILED state
   # send FAILED state, expected TRUE
   # send OK state, expected FALSE
   # send OK state, expected TRUE
   echo "FAILED:$(date +%s):120" > $STATE_FILE

   # call UUT
   prohibit_output "failed" || failed "final FAILED, expected TRUE, received FALSE"
   prohibit_output "ok" && failed "first OK, expected FALSE, received TRUE"
   prohibit_output "ok" || failed "second OK, expected TRUE, received FALSE"


   passed
   unset TEST_CASE
   return 0
}

function test_case_05()
{
   # given a the system being in a FAILED state, one or
   # multiple messages within PERIODICITY are being
   # ignored and logging is prohibited, a message after
   # the timer exceeded is no longer prohibited
   TEST_CASE=${FUNCNAME[0]}
   local EXP_PERIODICITY=666

   # setup, generate STATE_FILE and fake the timestamp
   rm -f ${STATE_FILE}
   local TS=$(date +%s)
   echo "FAILED:$(expr $TS - $EXP_PERIODICITY + 1):${EXP_PERIODICITY}" > ${STATE_FILE}

   # call UUT
   prohibit_output "failed" || failed "100 seconds ago, ${EXP_PERIODICITY}s periodicity"
   sleep 2
   prohibit_output "failed" && failed "> ${EXP_PERIODICITY} seconds, we expect a go for logging"

   passed
   unset TEST_CASE
   return 0
}


function test_case_06()
{
   # given a test system being in UNKNOWN state (no STATE file)
   # a failed command is not expected to prohibit logging
   TEST_CASE=${FUNCNAME[0]}

   # setup, put system in UNKNOWN state
   rm -f ${STATE_FILE}

   # call UUT
   prohibit_output "failed" && failed "unknown => failed should result into FALSE"

   passed
   unset TEST_CASE
   return 0
}

function test_case_07()
{
   # given a system in UNKNOWN state, running INIT create a STATE
   # file that contains UNKNOWN:TS:PERIODICITY
   TEST_CASE=${FUNCNAME[0]}
   local EXP_PERIODICITY=777

   # setup
   rm -f $STATE_FILE

   # call UUT
   prohibit_output "init" EXP_PERIODICITY

   # assertions
   NEW_STATE=$(get_state)
   NEW_PERIOD=$(get_periodicity)
   [[ $NEW_STATE != "UNKNOWN" ]] && \
      failed "expected UNKNOWN, received ${NEW_STATE}"
   [[ $NEW_PERIOD -ne $EXP_PERIODICITY ]] && \
      failed "unexpected periodicity of ${NEW_PERIOD}"

   passed
   unset TEST_CASE
   return 0
}

function test_case_08()
{
   # given an already initiated system (either FAILED or OK), running INIT will update the
   # STATE file with the new periodicity
   TEST_CASE=${FUNCNAME[0]}
   local NEW_TS=$(date +%s)
   local EXP_PERIODICITY_1=333
   local EXP_PERIODICITY_2=444
   local NEW_PERIOD=0
   local NEW_STATE="BENIFY"

   # setup
   echo "OK:${NEW_TS}:${EXP_PERIODICITY_1}" > ${STATE_FILE}

   # call UUT
   prohibit_output "init" ${EXP_PERIODICITY_2}

   # assertions
   NEW_PERIOD=$(get_periodicity)
   [[ $NEW_PERIOD -ne $EXP_PERIODICITY_2 ]] && \
      failed "unexpected periodicity, expected ${EXP_PERIODICITY_2}, received ${NEW_PERIOD}"

   # call UUT
   prohibit_output "ok"
   NEW_STATE=$(get_state)
   [[ $NEW_STATE != "OK" ]] && failed "invalid state, expected OK, received ${NEW_STATE}"


   passed
   unset TEST_CASE
   return 0
}




# HERE STARTS MAIN ###
echo "Start testing..."
test_case_01
test_case_02
test_case_03
test_case_04
test_case_05
test_case_06
test_case_07
test_case_08
echo "ALL TESTS PASSED"
exit 0
