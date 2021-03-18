#!/usr/bin/env bash
# -------------------------------------------------------------------------
# This is the Unix startup script with aws-cli command finding unuse resources
# - EIP
# - snapshot
# - volume
# - ELB
# - SecurityGroups

# Author : Mak Sophea
# Version : 1.0
# 
# -------------------------------------------------------------------------
DATE="$(date +'%d-%m-%Y')"

#--region ap-southeast-1

REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')

echo "DATE SCAN : $DATE" 
echo "REGION : $REGION, ACCOUNT_ID : $ACCOUNT_ID"

source ./utils.sh

trim()
{
    local trimmed="$1"

    # Strip leading space.
    trimmed="${trimmed## }"
    # Strip trailing space.
    trimmed="${trimmed%% }"

    echo "$trimmed"
}

##EIP###
echo "=========Elastic IP - unassociated with instances========="
aws ec2 describe-addresses --query 'Addresses[?InstanceId==null]' | jq  -r '.[].PublicIp'
# aws ec2 describe-addresses --query 'Addresses[?InstanceId==null]' | jq  '.[].PublicIp'
#3.1.172.89
#54.255.16.25
#eips=( $(aws ec2 describe-addresses --query 'Addresses[?InstanceId==null]' | jq  '.[].PublicIp'))
#echo "Array size: " ${#eips[@]}
#echo "Array elements: "${eips[@]}

source ./ami.sh

source ./ec2_snapshot.sh

#####Unattached Volumes

echo "=========Unattached Volumes=====(aws ec2 delete-volume --volume-id)===="
aws ec2 describe-volumes | jq '.Volumes[] | select(.Attachments | length <= 0)  | {snaphotId: .SnapshotId, volumeId: .VolumeId, VolumeType: .VolumeType, size: (.Size|tostring + " GB" )    } | join("  - ")' 
#echo "Unattached EBS volumes: (aws ec2 delete-volume --volume-id)"
#aws ec2 describe-volumes --query 'Volumes[?State==`available`].{ID: VolumeId, State: State}' --output json | jq -c '.[]' | jq -r '.ID' #| awk -v ORS=' ' '{ print $1  }' | sed 's/ $//'


### RDS Snaphosts
echo "============Scanning RDS snapshots============="
#aws rds describe-db-snapshots | jq -r '.DBSnapshots[] |  [("ID:" +.DBSnapshotIdentifier), ("CreateTime:" + .SnapshotCreateTime)] | join (" ")' | tr -d '[]," '

rds_date=$(aws rds describe-db-snapshots | jq -r '.DBSnapshots[] |  [("ID:" +.DBSnapshotIdentifier), ("CreateTime:" + .SnapshotCreateTime)] | join (" ")' | tr -d '[]," ')
for item in ${rds_date}
do
	created_date=$(echo $item |  awk '{split($0,a,"CreateTime:"); print a[2]}')
	id=$(echo $item |  awk '{split($0,a,"CreateTime:"); print a[1]}')
	age=$(dateDiff -d "$created_date" "$now")
	if ((age > 90)); then
		echo "$id (Created $(($age/30)) months ago)"
	else
		echo "$id (Created $age days ago)"
	fi
done

### #Securit Groups


list_sg=$(aws ec2 describe-security-groups  --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}" | jq '.[] | {ID: ("ID:" + .ID), Name: ("Name:" + .Name)} | join (" - ")'| tr -d '[]," ')
#aws ec2 describe-security-groups  --query "SecurityGroups[*].{Name:GroupName,ID:GroupId}" | jq -r '.[] | {ID: ("ID:" + .ID), Name: ("Name:" + .Name)} | join (" - ")' > list_sg.txt
arrVar=()
#echo "">unuse_sg.txt
# Add new element at the end of the array
#arrVar[${#arrVar[@]}]="Python"

ec2_sg=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=running,stopped | jq '.Reservations[].Instances[] | {SecurityGroups: .SecurityGroups}' | jq  '.SecurityGroups[].GroupId'  | tr -d '[]," ')
#echo "Array size:  ${#ec2_sg[@]} "
#echo "Array elements: ${ec2_sg[@]}"
echo "================Active Security Groups =============="

for item in ${ec2_sg}
do
	echo "Security Groug used by instance:" $(trim "$item")
done

echo "================Unused Security Groups=============="

for line in ${list_sg}
#while read -r line
do
   value=""
   for item in ${ec2_sg}
   do
		v="$(trim "$item")"
  		if [[ "$line" == *"$v"* ]]; then
  			value="$line"
			break
		fi
   done
  #  arrVar+=("$line")
  if [[ -z "$value" ]]; then
		 arrVar+=("$line")
		#echo  $line >> unuse_sg.txt
   fi
done 
#done < list_sg.txt

for value in "${arrVar[@]}"
do
     echo $value
done

#ELB
echo "================ELB =============="
aws elbv2 describe-load-balancers | jq '.LoadBalancers[] | {LoadBalancerName: ("Name:" + .LoadBalancerName), State: ("State: " + .State.Code) } | join (" - ")' 

