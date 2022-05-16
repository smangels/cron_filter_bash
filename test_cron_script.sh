
source ./cron_script.sh

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

   # setup
   rm -f $STATE_FILE

   # call UUT
   EXP_PERIODICITY=120
   prohibit_output "ok" 120

   # assertions
   if ! [ -f ${STATE_FILE} ]; then
      debug "ERROR: we expected a state file in ${STATE_FILE}"
      return 0
   fi
   PERIODICITY=$(get_periodicity)
   if ! [[ ${PERIODICITY} == ${EXP_PERIODICITY} ]]; then
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
   prohibit_output "ok" 120 && failed "expected 0 received 1"
   prohibit_output "ok" 120 || failed "expected 1, received 0"

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
   prohibit_output "failed" 120 || failed "final FAILED, expected TRUE, received FALSE"
   prohibit_output "ok" 120 && failed "first OK, expected FALSE, received TRUE"
   prohibit_output "ok" 120 || failed "second OK, expected TRUE, received FALSE"


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

   # setup, generate STATE_FILE and fake the timestamp
   local TS=$(date +%s)
   echo "FAILED:$(expr $TS - 179):180" > ${STATE_FILE}

   # call UUT
   prohibit_output "failed" 180 || failed "100 seconds ago, 120s periodicity"
   sleep 2
   prohibit_output "failed" 180 && failed "> 180 seconds, we expect a go for logging"

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
   prohibit_output "failed" 120 && failed "unknown => failed should result into FALSE"

   passed
   unset TEST_CASE
   return 0
}



echo "Start testing..."
test_case_01
test_case_02
test_case_03
test_case_04
test_case_05
test_case_06
echo "ALL TESTS PASSED"
exit 0
