#!/bin/bash
set -euo pipefail

URL=$1
TENANT=$2
ENDPOINT_TYPE=$3

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
error_message=$(echo "${iam_response}" | jq 'has("errorMessage")')

if [[ "${error_message}" != false ]]; then
  echo "${iam_response}" | jq '.errorMessage' >&2
  echo "Could not obtain an IAM access token" >&2
  exit 1
fi
iam_token=$(echo "${iam_response}" | jq -r '.access_token')

# ---- List and Delete policies -------------------------------------------------
echo "Starting policy cleanup (with retries)..."

MAX_ATTEMPTS=15
ATTEMPT=0

while ((ATTEMPT < MAX_ATTEMPTS)); do
  ATTEMPT=$((ATTEMPT + 1))
  echo "=== Cleanup attempt $ATTEMPT/$MAX_ATTEMPTS ==="

  # Get fresh list of policy IDs – safe even when .policies is missing or empty
  POLICY_IDS=$(curl -s \
    -H "Authorization: Bearer ${iam_token}" \
    -H "X-IBM-Tenant-Id: ${TENANT}" \
    "https://${URL}/v2/data-protect/policies" |
    jq -r '.policies // [] | .[].id // empty')

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
