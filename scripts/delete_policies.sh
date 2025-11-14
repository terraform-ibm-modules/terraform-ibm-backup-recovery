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
curl -s \
  -H "Authorization: Bearer ${iam_token}" \
  -H "X-IBM-Tenant-Id: ${TENANT}" \
  "https://${URL}/v2/data-protect/policies" |
  jq -r '.policies[].id' |
  while read -r id; do
    echo "Deleting ${id} ..."
    curl -s -X DELETE -o /dev/null \
      -H "Authorization: Bearer ${iam_token}" \
      -H "X-IBM-Tenant-Id: ${TENANT}" \
      "https://${URL}/v2/data-protect/policies/${id}" && echo "OK"
  done

sleep 30
