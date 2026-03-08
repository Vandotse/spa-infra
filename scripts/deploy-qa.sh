#!/bin/bash
set -euo pipefail

: "${QA_EC2_IP:?QA_EC2_IP is empty}"
: "${QA_EC2_USER:?QA_EC2_USER is empty}"
: "${AWS_REGION:?AWS_REGION is empty}"
: "${ECR_BACKEND_REPO:?ECR_BACKEND_REPO is empty}"
: "${ECR_FRONTEND_REPO:?ECR_FRONTEND_REPO is empty}"

echo "Deploying to QA EC2: $QA_EC2_IP"

REGISTRY=$(echo "$ECR_BACKEND_REPO" | cut -d'/' -f1)
ECR_PASSWORD=$(aws ecr get-login-password --region "$AWS_REGION")

ssh "$QA_EC2_USER@$QA_EC2_IP" <<EOF
set -e

echo "$ECR_PASSWORD" | docker login --username AWS --password-stdin "$REGISTRY"

echo "Pulling latest images..."
docker pull "$ECR_BACKEND_REPO:latest"
docker pull "$ECR_FRONTEND_REPO:latest"

echo "Stopping old containers..."
docker stop backend || true
docker rm backend || true
docker stop frontend || true
docker rm frontend || true

echo "Starting backend..."
docker run -d \
  --restart unless-stopped \
  --name backend \
  -p 3000:3000 \
  -e DB_HOST="$RDS_HOST" \
  -e DB_PORT="$RDS_PORT" \
  -e DB_USER="$RDS_USER" \
  -e DB_PASSWORD="$RDS_PASSWORD" \
  -e DB_NAME="$RDS_DB_NAME" \
  "$ECR_BACKEND_REPO:latest"

echo "Starting frontend..."
docker run -d \
  --restart unless-stopped \
  --name frontend \
  -p 3001:3000 \
  "$ECR_FRONTEND_REPO:latest"

echo "Current containers:"
docker ps
EOF