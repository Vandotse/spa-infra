#!/bin/bash
set -xe

dnf update -y
dnf install -y docker docker-compose-plugin

echo "Running Docker..."
systemctl start docker
systemctl enable docker

docker --version
docker compose version