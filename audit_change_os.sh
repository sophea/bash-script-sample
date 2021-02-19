#!/usr/bin/env bash
# -------------------------------------------------------------------------
# This is the unix bash script
# Author : Mak Sophea
# Version : 1.0
# ./audit.sh "pattern_1" "pattern_2" "pattern_3"
# ./audit.sh "sinhuy-changes"
# -------------------------------------------------------------------------
start_time="$(date +%s%N)"

NUM_MINUTE="10"
DATE="$(date +'%m/%d/%Y')"
tmpFile="tmp_audit_$(date +'%m_%d_%Y').txt"
tmpResultFile="tmp_result_audit_$(date +'%m_%d_%Y').txt"
function processData() {
	#Define multi-character delimiter
	delimiter="####"
	#Concatenate the delimiter with the main string
	text="$1"
	string=$text$delimiter

	#Split the text based on the delimiter
	myarray=()
	while [[ $string ]]; do
	  myarray+=( "${string%%"$delimiter"*}" )
	  string=${string#*"$delimiter"}
	done

	myarray=("${myarray[@]:1}") #removed the 1st element

	#echo ${#myarray[@]} size arrray
	###first array item split with time--> replace by #  time->Thu Feb 18 17:09:19 2021
	#timeValue="${myarray[0]}"
	#timeValue="${timeValue/->/#}"
	#echo "timeValue $timeValue"
	## cut by # get second item
	date1=$(echo $timeValue | cut -d'#' -f 2)

	# do something with $line here
	date2=$(date +'%m/%d/%Y %H:%M:%S')

	diff=$(dateDiff -m "$date1" "$date2")
	echo "diff $diff minutes"
	
	 # check less than 10 minutes
	if (($diff <= $NUM_MINUTE)); then
		### skip the first item
		for line in "${myarray[@]}"; do
			echo $line
			echo $line >> $tmpResultFile
		done  
    fi
	echo "----" >> $tmpResultFile	
}


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

#######main process#############
####pattern search with params
for params in "${*:1}"
do
     ausearch -k "$params" >> $tmpFile
done

cat $tmpFile  > ${tmpFile}_result
### read file line by bline
##read file split by --- and put into arrays
i=0
declare -a list=()
while read line; do 
	if [[ "$line" == "----" ]]; then
		i=$((i+1))
		continue
	fi
	## append arrays ####	
	list[(($i-1))]="${list[(($i-1))]}####$line"
done < ${tmpFile}_result

#echo "----------------array list------------"
#echo ${#list[@]} #Number of elements in the array

###loop array
for line in "${list[@]}"; do
	processData "$line"
done


# check file existed
if [[ -f $tmpResultFile ]]; then
	##unique line from file
    cat $tmpResultFile | uniq -u > ${tmpResultFile}_unique
    rm $tmpResultFile
	if [[ -s "${tmpResultFile}_unique" ]]; then
		#do send mail the content ${tmpResultFile}_unique
		message="<h6>PLEASE BE AWARE OF THE FOLLOWING ALERT ISSUED DUE TO OS CRITICAIL FILE CHANGES ON POWERCARD DATABASE</h6><pre style="font-size:10px">$(cat "${tmpResultFile}_unique")</pre>"
		bodyText="$message <br/><br/>"
	 
		##Email notification
		from="dba@UAT.xxxx.com"
		to="sopheamak@gmail.com"
		subject="OS CRITICAIL FILE CHANGES IN POWERCARD DB"
		message="${bodyText}"
			(
			echo "From: ${from}";
			echo "To: ${to}";
			echo "Subject: ${subject}";
			echo "Content-Type: text/html";
			echo "MIME-Version: 1.0";
			echo "";
			echo "${message}";
		   ) | /usr/sbin/sendmail -t
		cat ${tmpResultFile}_unique
		##remove
		rm ${tmpResultFile}_unique
	else 
		echo "===========no content to send email=========="
	fi
else
    echo "=======No result found======"
fi


# check file existed
if [[ -f $tmpFile ]]; then
        rm $tmpFile
fi
rm ${tmpFile}_result

end_time="$(date +%s%N)"
elapsed="$((($end_time-$start_time)/1000000))"
echo "Total of ${elapsed} millis elapsed for process"
