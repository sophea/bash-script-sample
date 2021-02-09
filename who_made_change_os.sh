# -------------------------------------------------------------------------
# This is the unix bash script
# Author : Mak Sophea
# Version : 1.0
# ./audit.sh "pattern_1" "pattern_2" "pattern_3"
# ./audit.sh "sinhuy-changes"
# -------------------------------------------------------------------------

NUM_MINUTE="10"
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

DATE="$(date +'%m/%d/%Y')"

tmpFile="tmp_audit_$(date +'%m_%d_%Y').txt"
tmpResultFile="tmp_result_audit_$(date +'%m_%d_%Y').txt"
####pattern search with params
for params in "${*:1}"
do
        ausearch -k "$params" | aureport -f -i >> $tmpFile
done

cat $tmpFile | grep "${DATE}" > ${tmpFile}_result
### read file line by bline
cat ${tmpFile}_result | while read line
do
   # do something with $line here
   date1=`echo $line | awk '{ print $2 " " $3 }'`
   date2=$(date +'%m/%d/%Y %H:%M:%S')
  # find dateDiff as minute
   diff=$(dateDiff -m "$date1" "$date2")
   # check less than 10 minutes
   if (($diff <= $NUM_MINUTE)); then
        echo $line >> $tmpResultFile
   fi
done

# check file existed
if [[ -f $tmpResultFile ]]; then
        ##unique line from file
    cat $tmpResultFile | uniq -u > ${tmpResultFile}_unique
    rm $tmpResultFile
        #do send mail the content ${tmpResultFile}_unique
		
		 message="<h6>PLEASE BE AWARE OF THE FOLLOWING ALERT ISSUED DUE TO OS CRITICAIL FILE CHANGES ON POWERCARD DATABASE</h6><pre style="font-size:10px">$(cat "${tmpResultFile}_unique")</pre>"
 bodyText="$message <br/><br/>"
 
 ##Email notification
from="dba@UAT.jtrustroyal.com"
        to="youn.sinhuy@jtrustsystem.co.jp,sinhuy.youn@jtrustroyal.com"
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
    echo "=======No result found======"
fi


# check file existed
if [[ -f $tmpFile ]]; then
        rm $tmpFile
fi
rm ${tmpFile}_result
