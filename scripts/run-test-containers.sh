#!/bin/bash
set -euo pipefail

echo "Running verification containers on EC2..."

REMOTE_USER="ec2-user"
REMOTE_HOST="$EC2_IP"
REMOTE_DIR="~/spa-verify"

ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR"

echo "Transferring backend image..."
docker save spa-backend:latest | ssh "$REMOTE_USER@$REMOTE_HOST" "sudo docker load"

echo "Transferring frontend image..."
docker save spa-frontend:latest | ssh "$REMOTE_USER@$REMOTE_HOST" "sudo docker load"

echo "Copying verification compose file..."
scp compose/docker-compose.verify.yml "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/docker-compose.verify.yml"

echo "Creating .env on verification EC2..."
ssh "$REMOTE_USER@$REMOTE_HOST" <<EOF
cat > $REMOTE_DIR/.env <<EOT
RDS_HOST=$RDS_HOST
RDS_PORT=$RDS_PORT
RDS_USER=$RDS_USER
RDS_PASSWORD=$RDS_PASSWORD
RDS_DB_NAME=$RDS_DB_NAME
EOT
EOF

echo "Starting verification stack..."
ssh "$REMOTE_USER@$REMOTE_HOST" <<EOF
cd $REMOTE_DIR
sudo docker compose --env-file .env -f docker-compose.verify.yml up -d
sudo docker compose -f docker-compose.verify.yml ps
sudo docker images | grep -E 'spa-backend|spa-frontend'
EOF