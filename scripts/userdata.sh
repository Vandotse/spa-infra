#!/bin/bash
set -xe

exec > /var/log/userdata.log 2>&1

if command -v dnf >/dev/null 2>&1; then
  dnf update -y
  dnf install -y docker docker-compose-plugin git
elif command -v yum >/dev/null 2>&1; then
  yum update -y
  amazon-linux-extras install docker -y || true
  yum install -y docker git
else
  apt-get update -y
  apt-get install -y docker.io docker-compose-plugin git
fi

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user || true
usermod -aG docker ubuntu || true

docker --version || true
docker compose version || true