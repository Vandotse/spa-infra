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

echo "Before deploy:"
docker ps -a || true
sudo ss -tulpn | grep ':3000\|:3001' || true

echo "$ECR_PASSWORD" | docker login --username AWS --password-stdin "$BACKEND_REGISTRY"

if [ "$FRONTEND_REGISTRY" != "$BACKEND_REGISTRY" ]; then
  echo "$ECR_PASSWORD" | docker login --username AWS --password-stdin "$FRONTEND_REGISTRY"
fi

echo "Stopping named app containers if they exist..."
docker stop backend || true
docker rm backend || true
docker stop frontend || true
docker rm frontend || true

echo "Stopping any container publishing port 3000..."
PORT3000_IDS=\$(docker ps -q --filter "publish=3000" || true)
if [ -n "\$PORT3000_IDS" ]; then
  docker stop \$PORT3000_IDS || true
  docker rm \$PORT3000_IDS || true
fi

echo "Stopping any container publishing port 3001..."
PORT3001_IDS=\$(docker ps -q --filter "publish=3001" || true)
if [ -n "\$PORT3001_IDS" ]; then
  docker stop \$PORT3001_IDS || true
  docker rm \$PORT3001_IDS || true
fi

echo "Cleaning old Docker data..."
docker container prune -f || true
docker image prune -a -f || true

echo "Pulling latest images from ECR..."
docker pull "$ECR_BACKEND_REPO:latest"
docker pull "$ECR_FRONTEND_REPO:latest"

echo "Starting backend..."
docker run -d \
  -p 3000:3000 \
  --restart unless-stopped \
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
  --restart unless-stopped \
  --name frontend \
  "$ECR_FRONTEND_REPO:latest"

echo "After deploy:"
docker ps
sudo ss -tulpn | grep ':3000\|:3001' || true
EOF