#!/bin/bash
set -euo pipefail

: "${QA_EC2_IP:?QA_EC2_IP is empty}"
: "${QA_EC2_USER:?QA_EC2_USER is empty}"
: "${AWS_REGION:?AWS_REGION is empty}"
: "${ECR_BACKEND_REPO:?ECR_BACKEND_REPO is empty}"
: "${ECR_FRONTEND_REPO:?ECR_FRONTEND_REPO is empty}"

BACKEND_REGISTRY=$(echo "$ECR_BACKEND_REPO" | cut -d'/' -f1)
FRONTEND_REGISTRY=$(echo "$ECR_FRONTEND_REPO" | cut -d'/' -f1)

echo "Deploying to QA EC2: $QA_EC2_IP"

ECR_PASSWORD=$(aws ecr get-login-password --region "$AWS_REGION")

ssh -T -o StrictHostKeyChecking=no "${QA_EC2_USER}@${QA_EC2_IP}" <<EOF
set -e

echo "$ECR_PASSWORD" | docker login --username AWS --password-stdin "$BACKEND_REGISTRY"

if [ "$FRONTEND_REGISTRY" != "$BACKEND_REGISTRY" ]; then
  echo "$ECR_PASSWORD" | docker login --username AWS --password-stdin "$FRONTEND_REGISTRY"
fi

echo "Pulling latest images from ECR..."
docker pull "$ECR_BACKEND_REPO:latest"
docker pull "$ECR_FRONTEND_REPO:latest"

echo "Stopping old containers..."
docker stop backend || true
docker rm backend || true
docker stop frontend || true
docker rm frontend || true

echo "Starting backend..."
docker run -d \
  -p 3000:3000 \
  --name backend \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT="$DB_PORT" \
  -e DB_USER="$DB_USER" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e DB_NAME="$DB_NAME" \
  "$ECR_BACKEND_REPO:latest"

echo "Starting frontend..."
docker run -d \
  -p 3001:3000 \
  --name frontend \
  "$ECR_FRONTEND_REPO:latest"

docker ps
echo "QA deployment complete."
EOF