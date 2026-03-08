#!/bin/bash
set -euo pipefail

echo "Launching temporary EC2..."

INSTANCE_ID=$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --security-group-ids "$EC2_SECURITY_GROUP" \
  --subnet-id "$EC2_SUBNET" \
  --associate-public-ip-address \
  --key-name "$EC2_KEY_NAME" \
  --user-data file://scripts/userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nightly-verify-ec2}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "INSTANCE_ID=$INSTANCE_ID" >> "$GITHUB_ENV"

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
aws ec2 wait instance-status-ok --instance-ids "$INSTANCE_ID"

EC2_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "EC2_IP=$EC2_IP" >> "$GITHUB_ENV"

echo "Temporary EC2 launched:"
echo "  INSTANCE_ID=$INSTANCE_ID"
echo "  EC2_IP=$EC2_IP"