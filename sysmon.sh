#!/bin/bash

printf "%-10s%-15s%-15s%s\n" "PID" "OWNER" "MEMORY" "COMMAND"
function sysmon_main() {
	RWWIN=$(ps -o pid,user,%mem,command ax | grep -v PID | awk '/[0-9]*/{print $1 ":" $2 ":" $4}')
	for i in $RWWIN
	do
		PID=$(echo $i | cut -d: -f1)
		OWNER=$(echo $i | cut -d: -f2)
		COMMAND=$(echo $i | cut -d: -f3)
		MEMORY=$(pmap $PID | tail -n 1 | awk '/[0-9]/{print $2}')
		MEMORY=$(echo "$(( ${MEMORY::-1} / 1024)) MB")
		printf "%-10s%-15s%-15s%s\n" "$PID" "$OWNER" "$MEMORY" "$COMMAND"
	done
}

sysmon_main | sort -bnr -k3
