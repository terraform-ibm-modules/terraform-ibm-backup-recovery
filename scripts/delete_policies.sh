#!/bin/bash
set -euo pipefail

URL=$1
TENANT=$2
ENDPOINT_TYPE=$3
# The binaries downloaded by the install-binaries script are located in the /tmp directory.
export PATH=$PATH:${4:-"/tmp"}


echo "=== Script execution started at $(date) ==="
echo "URL: $URL, TENANT: $TENANT, ENDPOINT_TYPE: $ENDPOINT_TYPE"

# decide the iam endpoint depending upon the IBMCLOUD_IAM_API_ENDPOINT env variable set by the user and
# whether provider visibility is public or private
iam_cloud_endpoint="${IBMCLOUD_IAM_API_ENDPOINT:-"iam.cloud.ibm.com"}"
IBMCLOUD_IAM_API_ENDPOINT=${iam_cloud_endpoint#https://}

if [[ "$IBMCLOUD_IAM_API_ENDPOINT" == "iam.cloud.ibm.com" ]]; then
  if [[ "$ENDPOINT_TYPE" == "private" ]]; then
    IBMCLOUD_IAM_API_ENDPOINT="private.${IBMCLOUD_IAM_API_ENDPOINT}"
  fi
fi

# generate iam_token from the ibmcloud_api_key. This will be used to make API requests to secrets manager instance endpoint for fetching and deleting secrets
iam_response=$(curl --retry 3 -s -X POST "https://${IBMCLOUD_IAM_API_ENDPOINT}/identity/token" --header 'Content-Type: application/x-www-form-urlencoded' --header 'Accept: application/json' --data-urlencode 'grant_type=urn:ibm:params:oauth:grant-type:apikey' --data-urlencode "apikey=$API_KEY") # pragma: allowlist secret


# Check for access_token immediately
iam_token=$(echo "${iam_response}" | jq -r '.access_token // empty' | tr -d '\n\r')

if [[ -z "$iam_token" || "$iam_token" == "null" ]]; then
  echo "Error: Could not obtain IAM access token." >&2
  echo "IAM Response: ${iam_response}" >&2
  exit 1
fi

# ---- List and Delete policies -------------------------------------------------
echo "Starting policy cleanup (with retries)..."

MAX_ATTEMPTS=15
ATTEMPT=0

while ((ATTEMPT < MAX_ATTEMPTS)); do
  ATTEMPT=$((ATTEMPT + 1))
  echo "=== Cleanup attempt $ATTEMPT/$MAX_ATTEMPTS ==="

  # Get fresh list of policy IDs with HTTP status check
  # Use a temp file for response body to separate body from status code
  RESP_FILE=$(mktemp)

  # Force --http1.1 to avoid potential H2 header handling issues
  # Add Content-Type and Accept to ensure strict middleware accepts it
  HTTP_CODE=$(curl --http1.1 -s -o "$RESP_FILE" -w "%{http_code}" \
    -H "Authorization: Bearer ${iam_token}" \
    -H "X-IBM-Tenant-Id: ${TENANT}" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    "https://${URL}/v2/data-protect/policies")

  BODY=$(cat "$RESP_FILE")
  rm "$RESP_FILE"

  if [[ "$HTTP_CODE" != "200" ]]; then
     echo "Error listing policies: HTTP $HTTP_CODE"
     echo "Response Body: $BODY"
     # If we can't list, we can't clean up. Fail immediately to let Terraform know.
     exit 1
  fi

  POLICY_IDS=$(echo "$BODY" | jq -r '.policies // [] | .[].id // empty')

  # If nothing left → we are done
  if [[ -z "$POLICY_IDS" ]]; then
    echo "No policies remain. Cleanup completed successfully!"
    break
  fi

  echo "Found $(echo "$POLICY_IDS" | wc -l | xargs) polic(ies) – attempting deletion..."

  echo "$POLICY_IDS" | while read -r id; do
    [[ -z "$id" ]] && continue
    echo -n "Deleting policy $id ... "

    for attempt in {1..5}; do
      result=$(curl -i -H "Authorization: Bearer ${iam_token}" -H "X-IBM-Tenant-Id: ${TENANT}" -X DELETE "https://${URL}/v2/data-protect/policies/${id}" 2>/dev/null)
      status_code=$(echo "$result" | head -n 1 | cut -d$' ' -f2)
      if [ "${status_code}" == "204" ] || [ "${status_code}" == "200" ]; then
        echo "OK"
        break
      else
        echo -n "failed (attempt $attempt)"
        echo "$result"
        if ((attempt == 5)); then
          echo "giving up on this policy for this attempt"
        else
          sleep 5
        fi
      fi
    done
  done

  if [[ -n "$POLICY_IDS" ]]; then
    echo "Some policies still present, waiting 20 seconds before next attempt..."
    sleep 20
  fi
done

# Final check + friendly message
if ((ATTEMPT >= MAX_ATTEMPTS)); then
  echo "ERROR: Reached maximum attempts. Some policies may still exist." >&2
  exit 1
else
  echo "All policies successfully cleaned up."
fi

sleep 30
