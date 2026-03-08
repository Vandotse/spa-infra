#!/bin/bash
set -e

AWS_ACCOUNT_ID="$1"
AWS_REGION="$2"
BACKEND_REPO="$3"
FRONTEND_REPO="$4"
IMAGE_TAG="$5"

ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

docker pull "${ECR_URL}/${BACKEND_REPO}:${IMAGE_TAG}"
docker pull "${ECR_URL}/${FRONTEND_REPO}:${IMAGE_TAG}"

docker rm -f api || true
docker rm -f frontend || true

docker run -d \
  --name api \
  --restart unless-stopped \
  --env-file /opt/spa/backend.env \
  -p 3000:3000 \
  "${ECR_URL}/${BACKEND_REPO}:${IMAGE_TAG}"

docker run -d \
  --name frontend \
  --restart unless-stopped \
  -p 3001:3000 \
  "${ECR_URL}/${FRONTEND_REPO}:${IMAGE_TAG}"

sudo systemctl reload nginx || true