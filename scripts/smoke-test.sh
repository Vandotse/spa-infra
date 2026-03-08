#!/bin/bash
set -euo pipefail

echo "Running smoke test against $EC2_IP..."

MAX_ATTEMPTS=40
SLEEP_SECONDS=5

for i in $(seq 1 $MAX_ATTEMPTS); do
  echo "Attempt $i/$MAX_ATTEMPTS"

  STATUS=$(curl --max-time 5 -s -o response.txt -w "%{http_code}" -X POST "http://$EC2_IP:3000/dbinit" || true)
  echo "DB init HTTP status: $STATUS"

  if [ "$STATUS" = "200" ]; then
    echo "Backend is ready"
    break
  fi

  echo "Service not ready yet..."
  sleep $SLEEP_SECONDS
done

echo "Creating database..."
curl -f -X POST "http://$EC2_IP:3000/dbinit"

echo "Creating table..."
curl -f -X POST "http://$EC2_IP:3000/tbinit"

echo "Waiting for table creation to finish..."
sleep 5

echo "Inserting test row..."
if ! curl -f -X POST "http://$EC2_IP:3000/user" \
  -H "Content-Type: application/json" \
  -d '{"data":"nightly-test"}'; then
  echo "Insert failed. Fetching backend logs..."
  ssh -o StrictHostKeyChecking=no ec2-user@$EC2_IP "sudo docker logs verify-api | tail -100 || true"
  exit 1
fi

echo "Reading rows back..."
RESPONSE=$(curl -f "http://$EC2_IP:3000/user")
echo "$RESPONSE"
echo "$RESPONSE" | grep "nightly-test"

FRONTEND_STATUS=$(curl --max-time 5 -s -o /dev/null -w "%{http_code}" "http://$EC2_IP:3001" || true)
echo "Frontend HTTP status: $FRONTEND_STATUS"

if [ "$FRONTEND_STATUS" != "200" ] && [ "$FRONTEND_STATUS" != "304" ]; then
  echo "Frontend check failed"
  exit 1
fi

echo "Smoke test passed"