#!/bin/bash
set -e

echo "Building backend image..."
docker build -t spa-backend ./spa-app/backend

echo "Building frontend image..."
docker build -t spa-frontend ./spa-app/frontend