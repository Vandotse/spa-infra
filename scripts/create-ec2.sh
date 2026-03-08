#!/bin/bash
set -euo pipefail

: "${AMI_ID:?AMI_ID is empty}"
: "${EC2_SECURITY_GROUP:?TEMP_SG_ID is empty}"
: "${EC2_SUBNET:?TEMP_SUBNET_ID is empty}"
: "${EC2_KEY_NAME:?TEMP_KEY_NAME is empty}"
: "${CONTROL_EC2_IP:?CONTROL_EC2_IP is empty}"
: "${CONTROL_EC2_USER:?CONTROL_EC2_USER is empty}"
: "${AWS_REGION:?AWS_REGION is empty}"

REMOTE_DIR="~/nightly-launch"

echo "Preparing control EC2 for remote launch..."
ssh "$CONTROL_EC2_USER@$CONTROL_EC2_IP" "mkdir -p $REMOTE_DIR"
scp scripts/userdata.sh "$CONTROL_EC2_USER@$CONTROL_EC2_IP:$REMOTE_DIR/userdata.sh"

echo "Launching temporary EC2 from control EC2 using LabRole..."
REMOTE_OUTPUT=$(ssh "$CONTROL_EC2_USER@$CONTROL_EC2_IP" bash <<EOF
set -euo pipefail

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_DEFAULT_PROFILE
export AWS_DEFAULT_REGION="$AWS_REGION"

INSTANCE_ID=\$(aws ec2 run-instances \
  --image-id "$AMI_ID" \
  --instance-type t2.micro \
  --security-group-ids "$EC2_SECURITY_GROUP" \
  --subnet-id "$EC2_SUBNET" \
  --associate-public-ip-address \
  --key-name "$EC2_KEY_NAME" \
  --user-data file://$REMOTE_DIR/userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=nightly-verify-ec2}]' \
  --query 'Instances[0].InstanceId' \
  --output text)

aws ec2 wait instance-running --instance-ids "\$INSTANCE_ID"
aws ec2 wait instance-status-ok --instance-ids "\$INSTANCE_ID"

EC2_IP=\$(aws ec2 describe-instances \
  --instance-ids "\$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "INSTANCE_ID=\$INSTANCE_ID"
echo "EC2_IP=\$EC2_IP"
EOF
)

echo "$REMOTE_OUTPUT"

INSTANCE_ID=$(echo "$REMOTE_OUTPUT" | awk -F= '/^INSTANCE_ID=/{print $2}' | tail -n1)
EC2_IP=$(echo "$REMOTE_OUTPUT" | awk -F= '/^EC2_IP=/{print $2}' | tail -n1)

: "${INSTANCE_ID:?Failed to capture INSTANCE_ID from remote launch}"
: "${EC2_IP:?Failed to capture EC2_IP from remote launch}"

echo "INSTANCE_ID=$INSTANCE_ID" >> "$GITHUB_ENV"
echo "EC2_IP=$EC2_IP" >> "$GITHUB_ENV"

echo "Temporary EC2 launched:"
echo "  INSTANCE_ID=$INSTANCE_ID"
echo "  EC2_IP=$EC2_IP"