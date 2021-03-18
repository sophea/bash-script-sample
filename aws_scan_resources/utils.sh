#!/usr/bin/env bash
date2stamp () {
date --utc --date "$1" +%s
}

dateDiff (){
   unit="day";
   case $1 in
        -s)   sec=1;  unit="seconds";    shift;;
        -m)   sec=60; unit="minutes";    shift;;
        -h)   sec=3600; unit="hours";  shift;;
        -d)   sec=86400;  shift;;
		-M)	  sec=$((86400*30)); shift;;
        *)    sec=86400;;
    esac
    #echo $1 $2
    dte1=$(date2stamp "$1")
    dte2=$(date2stamp "$2")

    diffSec=$((dte2-dte1))
        abs=1
    if ((diffSec < 0)); then
        abs=-1;
    fi
    echo $((diffSec/sec*abs))
}
# calculate the number of days between 2 dates
    # -s in sec. | -m in min. | -h in hours  | -d in days (default)
#    dateDiff -s "2006-10-01" "2006-10-31"
#    dateDiff -m "2006-10-01" "2006-10-31"
#    dateDiff -h "2006-10-01" "2006-10-02"
#    dateDiff -d "2006-10-01" "2006-10-31"
#  dateDiff  "2006-10-01" "2006-10-11"
##dateDiff -m "02/04/2021 11:12:34" "$(date +'%m/%d/%Y %H:%M:%S')"

# Check if array contains item [$1: item, $2: array name]
