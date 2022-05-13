#!/usr/bin/env bash

# provide bash code that helps to filter the state
# of a crontab when executed very frequently

# we assume that when this function is called
# no file 		=> UNKNOWN STATE
# file exists 	=> STATE=OK, change to FAIL,

set -ex

STATE_UNKNOWN="UNKNOWN"
STATE_FAIL="FAIL"
STATE_PERIODICITY_SEC=60
TEST_FILE="./test.me"

SIGNAL_FILE="/tmp/${0}.cron"
STATE="${STATE_UNKNOWN}"

function get_current_ts()
{
	echo $(date +%s)
}

function prohibit_email()
{
	# Commands: "ok", "fail"
	#  "ok":   reset and write status OK to state file
	#  "fail": write file if not exist
	# check whether state file exist
	# if there is a state file:
	#   read && when DIFF > periodicity => return FALSE
	#   else return FALSE
	# elif there is no FILE:
	#   create a file and return
	local CMD="${1}"
	if [[ $CMD == "ok" ]]; then
		echo "OK" > "${SIGNAL_FILE}"
	elif [[ $CMD == "fail" ]]; then
		if ! [ -e "${SIGNAL_FILE}" ]; then
			# state is unknown, create a file
			echo "FAILED:$(date +%s)" > "${SIGNAL_FILE}"
			return 1
		else
			# file exists, compute DIFF and compare with PERIODICITY
			TS_NOW=$(date +%s)
			STATE=$(cat ${SIGNAL_FILE} | cut -d ':' -f1)
			if [[ "OK" == "$STATE" ]]; then
				echo "FAILED:$(date +%s)" > ${SIGNAL_FILE}
				return 0
			elif [[ "FAILED" == "${STATE}" ]]; then
				TS_OLD=$(cat $SIGNAL_FILE | cut -d ':' -f2)
				DIFF=$(( TS_NOW - TS_OLD ))
				if [ $DIFF -gt 180 ]; then
					echo "FAILED:$(date +%s)" > "${SIGNAL_FILE}"
					return 1
				else
					return 0
				fi
			else
				echo "invalid state, not supported"
			fi
		fi
	fi
	return 1
}

function send_email()
{
	echo "SMTP: email sent"
}


if ! [ -e $TEST_FILE ]; then
	if ! prohibit_email "fail"; then
		send_email
		exit 1
	fi
else
	prohibit_email "ok"
fi

exit 0
