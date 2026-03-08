#!/bin/bash
set -euo pipefail

echo "Running containers on EC2..."

REMOTE_USER="ec2-user"
REMOTE_HOST="$EC2_IP"

echo "Transfer backend image..."
docker save spa-backend | ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "sudo docker load"

echo "Transfer frontend image..."
docker save spa-frontend | ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "sudo docker load"

echo "Start containers..."
ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" <<EOF
set -e

sudo docker stop verify-frontend verify-api 2>/dev/null || true
sudo docker rm verify-frontend verify-api 2>/dev/null || true

sudo docker run -d \
  --name verify-api \
  -p 3000:3000 \
  -e DB_HOST="$DB_HOST" \
  -e DB_PORT="$DB_PORT" \
  -e DB_USER="$DB_USER" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e DB_NAME="$DB_NAME" \
  spa-backend

sudo docker run -d \
  --name verify-frontend \
  -p 3001:3000 \
  spa-frontend

echo "=== docker ps -a ==="
sudo docker ps -a

echo "=== backend logs ==="
sudo docker logs verify-api || true

echo "=== frontend logs ==="
sudo docker logs verify-frontend || true
EOF