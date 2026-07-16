#!/bin/bash
# delete_connectors.sh
# Deletes all data-source connectors registered against a BRS connection.
# This must run BEFORE the connection itself is deleted, otherwise BRS will
# reject the connection-delete request if any connectors are still registered.
#
# Usage: delete_connectors.sh <URL> <TENANT> <ENDPOINT_TYPE> <CONNECTION_ID> [BINARIES_PATH]
# Env:   API_KEY   - IBM Cloud API key (sensitive; passed via environment)
set -euo pipefail

URL=$1
TENANT=$2
ENDPOINT_TYPE=$3
CONNECTION_ID=$4
# The binaries downloaded by install_dependencies are placed in BINARIES_PATH
# (defaults to /tmp, matching install-binaries.sh). Extend PATH so jq is found
# even when it is not globally installed on the runner.
export PATH=$PATH:${5:-"/tmp"}

echo "=== delete_connectors.sh started at $(date) ==="
echo "URL: $URL, TENANT: $TENANT, ENDPOINT_TYPE: $ENDPOINT_TYPE, CONNECTION_ID: $CONNECTION_ID"

# ---------------------------------------------------------------------------
# Obtain an IAM bearer token
# ---------------------------------------------------------------------------
iam_cloud_endpoint="${IBMCLOUD_IAM_API_ENDPOINT:-"iam.cloud.ibm.com"}"
IBMCLOUD_IAM_API_ENDPOINT="${iam_cloud_endpoint#https://}"

if [[ "$IBMCLOUD_IAM_API_ENDPOINT" == "iam.cloud.ibm.com" ]] && [[ "$ENDPOINT_TYPE" == "private" ]]; then
  IBMCLOUD_IAM_API_ENDPOINT="private.${IBMCLOUD_IAM_API_ENDPOINT}"
fi

iam_response=$(curl --retry 3 -s -X POST "https://${IBMCLOUD_IAM_API_ENDPOINT}/identity/token" --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept: application/json' --data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' --data-urlencode "apikey=$API_KEY") # pragma: allowlist secret

iam_token=$(echo "${iam_response}" | jq -r '.access_token // empty' | tr -d '\n\r')

if [[ -z "$iam_token" || "$iam_token" == "null" ]]; then
  echo "Error: Could not obtain IAM access token." >&2
  echo "IAM Response: ${iam_response}" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# List connectors for this connection
# ---------------------------------------------------------------------------
RESP_FILE=$(mktemp)
HTTP_CODE=$(curl --http1.1 -s -o "$RESP_FILE" -w "%{http_code}" \
  -H "Authorization: Bearer ${iam_token}" \
  -H "X-IBM-Tenant-Id: ${TENANT}" \
  -H "Accept: application/json" \
  "https://${URL}/v2/data-source-connectors?connectionId=${CONNECTION_ID}")

BODY=$(cat "$RESP_FILE")
rm "$RESP_FILE"

if [[ "$HTTP_CODE" != "200" ]]; then
  # A 404 means the connection is already gone — nothing to clean up.
  if [[ "$HTTP_CODE" == "404" ]]; then
    echo "Connection not found (HTTP 404) — nothing to delete. Exiting cleanly."
    exit 0
  fi
  echo "Error listing connectors: HTTP $HTTP_CODE" >&2
  echo "Response Body: $BODY" >&2
  exit 1
fi

CONNECTOR_IDS=$(echo "$BODY" | jq -r '.connectors // [] | .[].connectorId // empty')

if [[ -z "$CONNECTOR_IDS" ]]; then
  echo "No connectors registered against connection ${CONNECTION_ID}. Nothing to delete."
  exit 0
fi

echo "Found $(echo "$CONNECTOR_IDS" | wc -l | xargs) connector(s) to delete."

# ---------------------------------------------------------------------------
# Delete each connector (tolerate 404 — already gone is fine)
# ---------------------------------------------------------------------------
FAILED=0
while IFS= read -r connector_id; do
  [[ -z "$connector_id" ]] && continue
  echo -n "Deleting connector ${connector_id} ... "

  for attempt in {1..5}; do
    DRESP_FILE=$(mktemp)
    D_HTTP_CODE=$(curl --http1.1 -s -o "$DRESP_FILE" -w "%{http_code}" \
      -X DELETE \
      -H "Authorization: Bearer ${iam_token}" \
      -H "X-IBM-Tenant-Id: ${TENANT}" \
      "https://${URL}/v2/data-source-connectors/${connector_id}")
    DRESP_BODY=$(cat "$DRESP_FILE")
    rm "$DRESP_FILE"

    if [[ "$D_HTTP_CODE" == "204" || "$D_HTTP_CODE" == "200" || "$D_HTTP_CODE" == "404" ]]; then
      echo "OK (HTTP ${D_HTTP_CODE})"
      break
    fi

    echo -n "failed (attempt ${attempt}, HTTP ${D_HTTP_CODE}): ${DRESP_BODY} "
    if ((attempt == 5)); then
      echo ""
      echo "ERROR: Could not delete connector ${connector_id} after 5 attempts." >&2
      FAILED=1
    else
      sleep 5
    fi
  done
done <<< "$CONNECTOR_IDS"

if ((FAILED == 1)); then
  exit 1
fi

echo "All connectors deleted successfully."
