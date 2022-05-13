#!/usr/bin/env bash

# provide bash code that helps to filter the state
# of a crontab when executed very frequently


SIGNAL_FILE="/tmp/${0}.cron"
STATE="UNKNOWN"

function get_current_ts()
{
	local TS1
	TS1=$(date +%s)
	echo $TS1
}

function get_state_file()
{
	# read state file and parse the content
	local CONT=$(cat ${SIGNAL_FILE})
}


function test_signal_file()
{
	local _file="$1"
	return test -e "${_file}"
}


while true; do
	if test_signal_file ./signal_file.txt; then
		echo "found file, state OK"
	else
		echo "not found, state FAILED"
		break
	fi
done


TS1=$(get_current_ts)

# format, 10:1652453349:FAILED

TS2=$(get_current_ts)
echo $TS1 > $SIGNAL_FILE

DIFF=$(( TS2 - TS1 ))
echo "diff: $DIFF"

exit 0
