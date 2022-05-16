#!/usr/bin/env bash

# provide bash code that helps to filter the state
# of a crontab when executed very frequently

# we assume that when this function is called
# no file 		=> UNKNOWN STATE
# file exists 	=> STATE=OK, change to FAIL,


# signalling file format
# <STATE>:<EPOCH>:<PERIODICITY>

#set -ex


function prohibit_output()
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
	local SIGNAL_FILE="/tmp/${0}.cron"
	local CMD="${1^^}"
	local TS_NOW=$(date +%s)
	local PERIODICITY=180

	if [[ ${CMD} == "OK" ]]; then

		[ $# -gt 1 ] && PERIODICITY=$2
		if ! [ -e  $SIGNAL_FILE ]; then
			# UNKNOWN state, write state and return FALSE
			echo "OK::${PERIODICITY}" > "${SIGNAL_FILE}"
			return 1
		else
			# not in UNKNOWN state anymore, read current state
         STATE=$(cat ${SIGNAL_FILE} | cut -d ':' -f1)
         if [[ "FAILED" == ${STATE} ]]; then
            # transition from FAILED, state
            echo "FAILED => OK"
            echo "OK::${PERIODICITY}" > "${SIGNAL_FILE}"
            return 1
         else
            # we are alread in OK state, prohibit output
            echo "OK => OK"
            echo "OK::${PERIODICITY}" > "${SIGNAL_FILE}"
            return 0
         fi
		fi

	elif [[ ${CMD} == "FAILED" ]]; then

		if ! [ -e "${SIGNAL_FILE}" ]; then

         echo "UNKNOWN => FAILED"

			# state is unknown, create a file
			echo "${CMD}:${TS_NOW}:${PERIODICITY}" > "${SIGNAL_FILE}"
			return 1

		else
			# file exists, compute DIFF and compare with PERIODICITY
			STATE=$(cat ${SIGNAL_FILE} | cut -d ':' -f1)
			if [[ "OK" == ${STATE} ]]; then
            echo "OK => FAILED"
				echo "FAILED:${TS_NOW}:${PERIODICITY}" > ${SIGNAL_FILE}
				return 0
			elif [[ "FAILED" == ${STATE} ]]; then
            echo "FAILED => FAILED"
				TS_OLD=$(cat "${SIGNAL_FILE}" | cut -d ':' -f2)
				PERIODICITY=$(cat "${SIGNAL_FILE}" | cut -d ':' -f3)
				DIFF=$(( TS_NOW - TS_OLD ))
				if [ $DIFF -gt 180 ]; then
					echo "FAILED:${TS_NOW}:${PERIODICITY}" > "${SIGNAL_FILE}"
					return 1
				else
					return 0
				fi
			else
				echo "invalid state, not supported"
			fi
		fi
	else
		echo "UNKNOWN command \"${CMD}\"...."
		return 0
	fi
	return 1
}

