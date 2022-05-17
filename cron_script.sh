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
	local TS_OLD=0
	local DIFF
	local STATE=""
	local PERIODICITY=0

	if [[ ${CMD} == "INIT" ]] & [ $# -gt 1 ]; then
		PERIODICITY=$2

		if [ -f  $SIGNAL_FILE ]; then
			TS_OLD=$(cat "${SIGNAL_FILE}" | cut -d ':' -f2)
			STATE=$(cat "${SIGNAL_FILE}" | cut -d ':' -f1)
			echo "${STATE}:${TS_OLD}:${PERIODICITY}" > "${SIGNAL_FILE}"
		else
			echo "UNKNOWN:${TS_NOW}:${PERIODICITY}" > "${SIGNAL_FILE}"
		fi
	fi

	if [ -f $SIGNAL_FILE ]; then
		PERIODICITY=$(cat ${SIGNAL_FILE} | cut -d ':' -f3)
	fi

	if [[ ${CMD} == "OK" ]]; then

		if ! [ -f  $SIGNAL_FILE ]; then
			# UNKNOWN state, write state and return FALSE
			echo "OK::${PERIODICITY}" > "${SIGNAL_FILE}"
			return 1
		else
			# not in UNKNOWN state anymore, read current state
         STATE=$(cat ${SIGNAL_FILE} | cut -d ':' -f1)
         if [[ "FAILED" == ${STATE} ]]; then
            # transition from FAILED, state
            echo "OK::${PERIODICITY}" > "${SIGNAL_FILE}"
            return 1
         else
            # we are alread in OK state, prohibit output
            echo "OK::${PERIODICITY}" > "${SIGNAL_FILE}"
            return 0
         fi
		fi

	elif [[ ${CMD} == "FAILED" ]]; then

		if ! [ -f "${SIGNAL_FILE}" ]; then

			# state is unknown, create a file
			echo "${CMD}:${TS_NOW}:${PERIODICITY}" > "${SIGNAL_FILE}"
			return 1

		else
			# file exists, compute DIFF and compare with PERIODICITY
			STATE=$(cat ${SIGNAL_FILE} | cut -d ':' -f1)
			PERIODICITY=$(cat ${SIGNAL_FILE} | cut -d ':' -f1)

			if [[ "OK" == ${STATE} ]]; then
				echo "FAILED:${TS_NOW}:${PERIODICITY}" > ${SIGNAL_FILE}
				return 1
			elif [[ "FAILED" == ${STATE} ]]; then
				TS_OLD=$(cat "${SIGNAL_FILE}" | cut -d ':' -f2)
				PERIODICITY=$(cat "${SIGNAL_FILE}" | cut -d ':' -f3)
				DIFF=$(( TS_NOW - TS_OLD ))
				if [ $DIFF -gt $PERIODICITY ]; then
					echo "FAILED:${TS_NOW}:${PERIODICITY}" > "${SIGNAL_FILE}"
					return 1
				else
					return 0
				fi
			else
				# something is fishy with the state read from file
            return 1
			fi
		fi
	else
      # command is "unknown", do not prohibit
		return 1
	fi
	return 1
}

