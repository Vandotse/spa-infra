#!/bin/bash
set -euo pipefail

: "${AWS_REGION:?AWS_REGION is empty}"
: "${ECR_BACKEND_REPO:?ECR_BACKEND_REPO is empty}"
: "${ECR_FRONTEND_REPO:?ECR_FRONTEND_REPO is empty}"

echo "Logging into ECR..."
REGISTRY=$(echo "$ECR_BACKEND_REPO" | cut -d'/' -f1)

aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

echo "Tagging images..."
docker tag spa-backend:latest "$ECR_BACKEND_REPO:latest"
docker tag spa-frontend:latest "$ECR_FRONTEND_REPO:latest"

echo "Pushing backend..."
docker push "$ECR_BACKEND_REPO:latest"

echo "Pushing frontend..."
docker push "$ECR_FRONTEND_REPO:latest"

echo "ECR push complete."