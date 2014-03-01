#!/bin/bash
#
ami_ID=""
keyname=""
group_name=""
cli_profile=""
vpc_cidr=""
subnet_cidr=""
dst_cidr=""
security_group_ssh_port=""
security_group_source_ip=""
#
# Create VPC
#
vpc_id=`aws ${cli_profile} ec2 create-vpc --cidr-block ${vpc_cidr} | jq -r .Vpc.VpcId`
echo "${vpc_id}"
#
# Create VPC Subnet
#
subnet_ID=`aws ${cli_profile} ec2 create-subnet --vpc-id ${vpc_id} --cidr-block ${subnet_cidr} | jq .Subnet.SubnetId`
echo "${subnet_ID}"
#
# Create Internet Gateway
#
gateway_id=`aws ${cli_profile} ec2 create-internet-gateway | jq -r .InternetGateway.InternetGatewayId`
echo "${gateway_id}"
#
# Attache Internet Gateway to VPC
#
aws ${cli_profile} ec2 attach-internet-gateway --internet-gateway-id ${gateway_id} --vpc-id ${vpc_id} 
#
# Confirm Route Table
#
rtb_id=`aws ${cli_profile} ec2 describe-route-tables --filters Name=route.destination-cidr-block,Values="${vpc_cidr}" | jq -r '.RouteTables[]|.RouteTableId'`
echo "${rtb_id}"
#
# Create Default Gateway
#
aws ${cli_profile} ec2 create-route --route-table-id ${rtb_id} --destination-cidr-block ${dst_cidr} --gateway-id ${gateway_id}
#
# Create Security Group
#
security-group_ID=`aws ${cli_profile} ec2 create-security-group --group-name ${group_name} --description "${group_name}" --vpc-id ${vpc_id} | jq -r '.GroupId'`
echo "security-group_ID"
#
# Set Security Inbound Traffic
#
aws ${cli_profile} ec2 authorize-security-group-ingress --group-id ${security-group_ID} --protocol tcp --port ${security_group_ssh_port} --cidr ${security_group_source_ip}
#
# Create EC2 instance and Confirm Public IP address
#
instance_ID=`aws ${cli_profile} ec2 run-instances \
--image-id ${ami_ID} \
--count 1 \
--instance-type t1.micro \
--key-name ${keyname} \
--security-group-ids ${security-group_ID} \
--subnet-id ${subnet_ID} \
--associate-public-ip-address | jq -c -r '.Instances[]|.InstanceId'`
publicIpAddress=`aws ${cli_profile} ec2 describe-instances | jq -r '.Reservations[].Instances[]|select(.InstanceId=="${instance_ID}").PublicIpAddress'`
#
printf "${instance_ID}\n"
printf "${publicIpAddress}\n"
