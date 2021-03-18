#!/usr/bin/env bash

echo "=============AMIs=============="
AMI=($(aws ec2 describe-images --owner self --region ap-southeast-1  --query 'Images[*].{ID:ImageId,Name:Name}' | jq '.[] | [("ID : "+ .ID), ("Name :" + .Name)] | join (" ")' | tr -d '[]," '))
echo "    AIM Found ${#AMI[@]}"

# Get all running instances
echo "    ============EC2 instances used by AMIs============"
EC2_AMI=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].{Instance:InstanceId,ImageId:ImageId}' | jq '.[] |.[] | [("ec2-instance-id : "+ .Instance), ("image-id :" + .ImageId)] | join (" ")' | tr -d '[]," ')
AMI_USED=()
arrVar=()
for item in $EC2_AMI
do	
	imageId=$(echo $item |  awk '{split($0,a,"image-id:"); print a[2]}')
	ec2Id=$(echo $item |  awk '{split($0,a,"image-id:"); print a[1]}')
	echo "       $ec2Id - imageId : $imageId"
	AMI_USED+=("$imageId")

done

# Get all launch templates
AMI_LT=$(aws ec2 describe-launch-template-versions --launch-template-id lt-0965c75df853d69d7 | jq '.LaunchTemplateVersions[]| .LaunchTemplateData.ImageId' | tr -d '[]," ')

for item in $AMI_LT
do
	AMI_USED+=("$item")
done
####find unused AMI
for line in "${AMI[@]}"
do
   value=""
 #  echo "$line"
   for used in "${AMI_USED[@]}"
   do
		v="$used"
		
  		if [[ "$line" == *"$v"* ]]; then
  			value="$line"
			break
		fi
   done
  #  arrVar+=("$line")
  if [[ -z "$value" ]]; then
		 arrVar+=("$line")
   fi
done
echo "    ============UNUSED AMIs============"

###echo arrVar unused AMIs#####
for item in "${arrVar[@]}"
do
    imageId=$(echo $item |  awk '{split($0,a,"Name:"); print a[2]}')
	id=$(echo $item |  awk '{split($0,a,"Name:"); print a[1]}')
	echo "    - $id - Name : $imageId"
done
