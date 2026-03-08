#!/bin/bash
set -e

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

curl -f -X POST "http://$EC2_IP:3000/dbinit"
curl -f -X POST "http://$EC2_IP:3000/tbinit"

curl -f -X POST "http://$EC2_IP:3000/user" \
  -H "Content-Type: application/json" \
  -d '{"data":"nightly-test"}'

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