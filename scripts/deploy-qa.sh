#!/bin/bash
set -e

echo "Deploying SPA to QA EC2: $QA_EC2_IP"

ssh -T -o StrictHostKeyChecking=no ${QA_EC2_USER}@${QA_EC2_IP} << EOF
aws ecr get-login-password --region $AWS_REGION \
| docker login --username AWS --password-stdin $ECR_REPO

echo "Pulling latest images from ECR..."
docker pull $ECR_REPO:frontend
docker pull $ECR_REPO:backend

echo "Stopping old containers..."
docker stop frontend || true
docker rm frontend || true
docker stop backend || true
docker rm backend || true

echo "Starting backend..."
docker run -d \
  -p 3000:3000 \
  --name backend \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT="$DB_PORT" \
  -e DB_USER="$DB_USER" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e DB_NAME="$DB_NAME" \
  $ECR_REPO:backend

echo "Starting frontend..."
docker run -d \
  -p 3001:3000 \
  --name frontend \
  $ECR_REPO:frontend

docker ps
echo "QA deployment complete."
EOF