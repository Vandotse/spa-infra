#!/bin/bash
set -eux

dnf update -y
dnf install -y docker docker-compose-plugin git

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user