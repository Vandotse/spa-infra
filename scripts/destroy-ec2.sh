#!/bin/bash
set -euo pipefail

if [ -z "${INSTANCE_ID:-}" ]; then
  echo "INSTANCE_ID is empty; nothing to terminate."
  exit 0
fi

: "${CONTROL_EC2_IP:?CONTROL_EC2_IP is empty}"
: "${CONTROL_EC2_USER:?CONTROL_EC2_USER is empty}"
: "${AWS_REGION:?AWS_REGION is empty}"

echo "Terminating temporary EC2 $INSTANCE_ID from control EC2..."

ssh "$CONTROL_EC2_USER@$CONTROL_EC2_IP" bash <<EOF
set -euo pipefail
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE AWS_DEFAULT_PROFILE
export AWS_DEFAULT_REGION="$AWS_REGION"

aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" >/dev/null
echo "Terminate request sent for $INSTANCE_ID"
EOF