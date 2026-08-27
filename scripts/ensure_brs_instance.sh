#!/usr/bin/env bash
# ensure_brs_instance.sh
#
# Called by terraform_data.ensure_brs_instance via local-exec.
# Runs only on terraform apply (create/replace) — never on plan or destroy.
#
# All inputs come from environment variables so that values containing quotes,
# spaces, or braces are never shell-interpolated.
#
# Required environment variables (set by the local-exec environment block):
#   IBMCLOUD_API_KEY   - IBM Cloud API key
#   EXISTING_CRN       - If non-empty, output directly; no CLI call is made
#   INSTANCE_NAME      - Name for the new instance
#   SERVICE            - IBM Cloud service name (e.g. backup-recovery)
#   PLAN               - Service plan (e.g. premium)
#   LOCATION           - Region/location (e.g. us-east)
#   RESOURCE_GROUP_ID  - Resource group ID to target
#   PARAMETERS_JSON    - Optional JSON parameters string (may be empty)
#   SERVICE_ENDPOINTS  - Service endpoints type (e.g. public)
#
# Writes a single bare CRN string to stdout (captured to .brs_instance_crn).
# All other output goes to stderr.

set -euo pipefail

existing_crn="${EXISTING_CRN:-}"
instance_name="${INSTANCE_NAME:-}"
service="${SERVICE:-}"
plan="${PLAN:-}"
location="${LOCATION:-}"
resource_group_id="${RESOURCE_GROUP_ID:-}"
parameters_json="${PARAMETERS_JSON:-}"

# ── 1. Short-circuit: existing CRN supplied ──────────────────────────────────
if [[ -n "$existing_crn" ]]; then
  echo >&2 "[ensure_brs_instance] EXISTING_CRN supplied – using it directly."
  printf '%s' "$existing_crn"
  exit 0
fi

# ── Validate API key ─────────────────────────────────────────────────────────
if [[ -z "${IBMCLOUD_API_KEY:-}" ]]; then
  echo >&2 "[ensure_brs_instance] ERROR: IBMCLOUD_API_KEY is not set."
  exit 1
fi

# ── Login ─────────────────────────────────────────────────────────────────────
echo >&2 "[ensure_brs_instance] Logging in to IBM Cloud…"
ibmcloud login --apikey "$IBMCLOUD_API_KEY" -q >&2

echo >&2 "[ensure_brs_instance] Targeting resource group ${resource_group_id}…"
ibmcloud target -g "$resource_group_id" -q >&2

# ── 2. Look up an existing instance by name ───────────────────────────────────
echo >&2 "[ensure_brs_instance] Looking up instance '${instance_name}'…"
lookup_json=$(ibmcloud resource service-instance "$instance_name" --output json 2>/dev/null || true)

found_crn=$(echo "$lookup_json" | jq -r '
  if type == "array"   then (.[0].crn // "")
  elif type == "object" then (.crn     // "")
  else "" end' 2>/dev/null || true)

if [[ -n "$found_crn" && "$found_crn" != "null" ]]; then
  echo >&2 "[ensure_brs_instance] Found existing instance. CRN: ${found_crn}"
  printf '%s' "$found_crn"
  exit 0
fi

# ── 3. Create the instance ────────────────────────────────────────────────────
echo >&2 "[ensure_brs_instance] Instance not found – creating '${instance_name}'…"

create_cmd=(ibmcloud resource service-instance-create
  "$instance_name"
  "$service"
  "$plan"
  "$location"
)

if [[ -n "$parameters_json" ]]; then
  create_cmd+=(-p "$parameters_json")
fi

create_output=$("${create_cmd[@]}" 2>&1)
echo >&2 "$create_output"

# Extract CRN directly from create output — avoids a second lookup while the
# instance is still in "provisioning" state (which returns non-JSON text).
new_crn=$(echo "$create_output" | grep -oE 'crn:v1:[^ ]+' | head -1)

if [[ -z "$new_crn" ]]; then
  echo >&2 "[ensure_brs_instance] ERROR: Could not find CRN in create output."
  exit 1
fi

# ── Wait for 'active' state ───────────────────────────────────────────────────
echo >&2 "[ensure_brs_instance] Waiting for instance to become active…"
MAX_ATTEMPTS=60
INTERVAL=10
attempt=0

while (( attempt < MAX_ATTEMPTS )); do
  attempt=$(( attempt + 1 ))
  state_json=$(ibmcloud resource service-instance "$new_crn" --output json 2>/dev/null || true)
  state=$(echo "$state_json" | jq -r '
    if type == "array"   then (.[0].state // "")
    elif type == "object" then (.state     // "")
    else "" end' 2>/dev/null || true)

  echo >&2 "[ensure_brs_instance] Attempt ${attempt}/${MAX_ATTEMPTS}: state=${state}"

  if [[ "$state" == "active" ]]; then
    echo >&2 "[ensure_brs_instance] Instance is active."
    break
  fi

  if (( attempt == MAX_ATTEMPTS )); then
    echo >&2 "[ensure_brs_instance] ERROR: Instance did not become active after $(( MAX_ATTEMPTS * INTERVAL ))s."
    exit 1
  fi

  sleep "$INTERVAL"
done

echo >&2 "[ensure_brs_instance] Done. CRN: ${new_crn}"
printf '%s' "$new_crn"
