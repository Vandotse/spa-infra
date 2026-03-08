#!/bin/bash

echo "Destroying temporary EC2..."

aws ec2 terminate-instances \
  --instance-ids "$INSTANCE_ID"