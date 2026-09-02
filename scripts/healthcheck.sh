#!/usr/bin/env bash
set -euo pipefail

# healthcheck.sh
# Issues an HTTP request against a target URL and asserts a 200 response.
# Usage: healthcheck.sh [URL]
#   URL defaults to http://localhost:8080

TARGET_URL="${1:-http://localhost:8080}"

echo "Checking ${TARGET_URL} ..."

set +e
http_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${TARGET_URL}")
curl_exit=$?
set -e

if [ "${curl_exit}" -ne 0 ]; then
    http_status="000"
fi

if [ "${http_status}" -eq 200 ]; then
    echo "OK: ${TARGET_URL} returned HTTP ${http_status}"
    exit 0
else
    echo "FAIL: ${TARGET_URL} returned HTTP ${http_status} (expected 200)" >&2
    exit 1
fi
