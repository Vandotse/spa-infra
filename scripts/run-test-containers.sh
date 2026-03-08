#!/bin/bash
set -e

echo "Running containers on EC2..."

docker save spa-backend | ssh -o StrictHostKeyChecking=no ec2-user@$EC2_IP "sudo docker load"
docker save spa-frontend | ssh -o StrictHostKeyChecking=no ec2-user@$EC2_IP "sudo docker load"

scp -o StrictHostKeyChecking=no docker-compose.deploy.yml ec2-user@$EC2_IP:docker-compose.yml

ssh -o StrictHostKeyChecking=no ec2-user@$EC2_IP << EOF
cat <<ENV > .env
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
ENV

cat .env

sudo docker compose -f docker-compose.yml --env-file .env up -d

sudo docker ps
sudo docker images
sudo docker logs \$(sudo docker ps --format '{{.Names}}' | grep api | head -n1) --tail 50 || true
sudo docker logs \$(sudo docker ps --format '{{.Names}}' | grep frontend | head -n1) --tail 50 || true
EOF