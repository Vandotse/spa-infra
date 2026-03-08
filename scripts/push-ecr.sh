#!/bin/bash
set -e

echo "Logging into ECR..."
REGISTRY=$(echo $ECR_REPO | cut -d'/' -f1)

aws ecr get-login-password --region $AWS_REGION \
| docker login --username AWS --password-stdin $REGISTRY

echo "Tagging images..."
docker tag spa-backend:latest $ECR_REPO:backend
docker tag spa-frontend:latest $ECR_REPO:frontend

echo "Pushing images..."
docker push $ECR_REPO:backend
docker push $ECR_REPO:frontend