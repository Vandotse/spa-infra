#!/bin/bash
set -euo pipefail

: "${AWS_REGION:?AWS_REGION is empty}"
: "${ECR_BACKEND_REPO:?ECR_BACKEND_REPO is empty}"
: "${ECR_FRONTEND_REPO:?ECR_FRONTEND_REPO is empty}"

BACKEND_REGISTRY=$(echo "$ECR_BACKEND_REPO" | cut -d'/' -f1)
FRONTEND_REGISTRY=$(echo "$ECR_FRONTEND_REPO" | cut -d'/' -f1)

if [[ "$BACKEND_REGISTRY" != *.amazonaws.com ]]; then
  echo "ECR_BACKEND_REPO is invalid: $ECR_BACKEND_REPO"
  exit 1
fi

if [[ "$FRONTEND_REGISTRY" != *.amazonaws.com ]]; then
  echo "ECR_FRONTEND_REPO is invalid: $ECR_FRONTEND_REPO"
  exit 1
fi

echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$BACKEND_REGISTRY"

# Usually both repos are in the same registry/account, so one login is enough.
# If they are in different registries/accounts, also log into FRONTEND_REGISTRY.
if [[ "$FRONTEND_REGISTRY" != "$BACKEND_REGISTRY" ]]; then
  aws ecr get-login-password --region "$AWS_REGION" \
    | docker login --username AWS --password-stdin "$FRONTEND_REGISTRY"
fi

echo "Tagging images..."
docker tag spa-backend:latest "$ECR_BACKEND_REPO:latest"
docker tag spa-frontend:latest "$ECR_FRONTEND_REPO:latest"

echo "Pushing backend..."
docker push "$ECR_BACKEND_REPO:latest"

echo "Pushing frontend..."
docker push "$ECR_FRONTEND_REPO:latest"

echo "ECR push complete."