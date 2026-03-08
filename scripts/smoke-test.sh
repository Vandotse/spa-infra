#!/bin/bash
set -euo pipefail

: "${EC2_IP:?EC2_IP is empty}"

MAX_ATTEMPTS=40
SLEEP_SECONDS=5

wait_for_url() {
  local url="$1"
  local label="$2"

  echo "Waiting for $label at $url ..."
  for i in $(seq 1 "$MAX_ATTEMPTS"); do
    STATUS=$(curl --max-time 5 -s -o /dev/null -w "%{http_code}" "$url" || true)
    echo "Attempt $i/$MAX_ATTEMPTS -> HTTP $STATUS"
    if [ "$STATUS" = "200" ] || [ "$STATUS" = "304" ]; then
      echo "$label is ready"
      return 0
    fi
    sleep "$SLEEP_SECONDS"
  done

  echo "$label never became ready"
  return 1
}

wait_for_url "http://$EC2_IP:3001" "frontend"
wait_for_url "http://$EC2_IP:3000/user" "backend"

echo "Initializing database..."
curl -f -X POST "http://$EC2_IP:3000/dbinit"

echo "Initializing table..."
curl -f -X POST "http://$EC2_IP:3000/tbinit"

echo "Inserting test row..."
curl -f -X POST "http://$EC2_IP:3000/user" \
  -H "Content-Type: application/json" \
  -d '{"data":"nightly-test"}'

echo "Reading rows back..."
RESPONSE=$(curl -f "http://$EC2_IP:3000/user")
echo "$RESPONSE"
echo "$RESPONSE" | grep "nightly-test"

echo "Smoke test passed."