#!/bin/bash
set -xe

exec > /var/log/userdata.log 2>&1

yum update -y
yum install -y docker git

service docker start
systemctl enable docker

usermod -aG docker ec2-user || true

docker --version