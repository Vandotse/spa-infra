#!/bin/bash
set -euo pipefail

echo "Building backend image..."
docker build -t spa-backend:latest ./app/backend

echo "Building frontend image..."
docker build -t spa-frontend:latest ./app/frontend

echo "Built images:"
docker images | grep -E 'spa-backend|spa-frontend'