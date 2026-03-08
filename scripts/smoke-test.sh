#!/bin/bash
set -euo pipefail

echo "Checking frontend..."
curl -f http://localhost:3001 > /dev/null

echo "Initializing database..."
curl -f -X POST http://localhost:3000/dbinit > /dev/null

echo "Initializing table..."
curl -f -X POST http://localhost:3000/tbinit > /dev/null

echo "Inserting a test row..."
curl -f -X POST http://localhost:3000/user \
  -H "Content-Type: application/json" \
  -d '{"data":"nightly-test"}' > /dev/null

echo "Reading rows back..."
curl -f http://localhost:3000/user | grep nightly-test

echo "Smoke tests passed."