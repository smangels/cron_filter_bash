
source ./cron_script.sh

TEST_CASE=""
STATE_FILE="/tmp/${0}.cron"
function died()
{
	echo "${TEST_CASE} - FAILED"
}

function debug()
{
	echo "${TEST_CASE} - $1"
}

function _get_item()
{
	cat $STATE_FILE | cut -d ':' -f${1}
}

function get_periodicity()
{
	_get_item 3
}

function get_timestamp()
{
	_get_item 2
}

function get_state()
{
	_get_item 1
}

function test_case_01()
{
	# given there is no state file in temp, init command
	# creates one and set provided periodicity in seconds
	TEST_CASE=${FUNCNAME[0]}

	# setup
	rm -f $STATE_FILE

	# call UUT
	prohibit_email "ok" 120

	# assertions
	if ! [ -f ${STATE_FILE} ]; then
		debug "ERROR: we expected a state file in ${STATE_FILE}"
		return 0
	fi
	PERIODICITY=$(get_periodicity)
	if ! [[ ${PERIODICITY} == 120 ]]; then
		debug "ERROR: we expected PERIODICITY: 120, got ${PERIODICITY}"
		return 0
	fi
	EXP_STATE="OK"
	STATE=$(get_state)
	if ! [[ $STATE == $EXP_STATE ]]; then
		debug "ERROR: expected state $EXP_STATE, received $STATE"
		return 0
	fi

	debug "PASSED" && unset TEST_CASE
	return 0
}

function test_case_02()
{
	TEST_CASE=${FUNCNAME[0]}
}


echo "Start testing..."
test_case_01 || died
echo "ALL TESTS PASSED"
exit 0
