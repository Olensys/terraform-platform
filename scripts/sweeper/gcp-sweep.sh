#!/usr/bin/env bash
# Delete leaked integration-test resources from the dedicated Google Cloud test project.
#
# Usage: gcp-sweep.sh PROJECT_ID DRY
#   DRY=true prints what would be deleted; anything else deletes.
# Env:   GCP_SERVICE_ACCOUNT  email of the CI service account (never deleted)
#
# A resource matches when it carries the label environment=test or its name starts
# with "olensys-test-". Resource types are processed in dependency order.
set -euo pipefail

PROJECT="${1:?usage: gcp-sweep.sh PROJECT_ID DRY}"
DRY="${2:?usage: gcp-sweep.sh PROJECT_ID DRY}"
CI_SA="${GCP_SERVICE_ACCOUNT:?GCP_SERVICE_ACCOUNT must be set to the CI service account email}"

gcloud config set project "$PROJECT" >/dev/null 2>&1
active="$(gcloud config get-value project 2>/dev/null)"
if [ "$active" != "$PROJECT" ]; then
  echo "refusing to run: active project '$active' is not '$PROJECT'" >&2
  exit 1
fi

# Labelled or prefixed. Resources whose name is a full resource path use PATH_FILTER.
FILTER='labels.environment=test OR name~^olensys-test-'
PATH_FILTER='labels.environment=test OR name~/olensys-test-'
FAILED=0

del() {
  if [ "$DRY" = true ]; then
    echo "would delete: $*"
  elif ! "$@" --quiet; then
    echo "FAILED: $*" >&2
    FAILED=$((FAILED + 1))
  fi
}

# sweep LABEL FILTER FIELDS HANDLER LIST_COMMAND...
# Lists matching rows as CSV (FIELDS), calls HANDLER with up to three fields, and
# prints "<label>: <n> matched".
sweep() {
  local label=$1 filter=$2 fields=$3 handler=$4
  shift 4
  local rows n=0 a b c
  rows="$("$@" --project "$PROJECT" --filter="$filter" --format="csv[no-heading]($fields)")"
  while IFS=, read -r a b c; do
    [ -n "$a" ] || continue
    n=$((n + 1))
    "$handler" "$a" "${b##*/}" "${c##*/}"
  done <<<"$rows"
  echo "$label: $n matched"
}

# Scope flags for compute resources: zonal, regional or global.
scope() {
  if [ -n "$1" ]; then
    echo "--zone=$1"
  elif [ -n "$2" ]; then
    echo "--region=$2"
  else
    echo "--global"
  fi
}

# compute_handler KIND: delete "gcloud compute <kind> delete NAME <scope>".
compute_delete() {
  local kind=$1 name=$2 zone=$3 region=$4
  # shellcheck disable=SC2046,SC2086
  del gcloud compute $kind delete "$name" $(scope "$zone" "$region") --project "$PROJECT"
}

# Handlers receive: name, second field (basename), third field (basename).
h_gke() { del gcloud container clusters delete "$1" --location "$2" --project "$PROJECT"; }
h_sql() {
  del gcloud sql instances patch "$1" --no-deletion-protection --project "$PROJECT"
  del gcloud sql instances delete "$1" --project "$PROJECT"
}
# Full resource path projects/P/locations/L/<collection>/NAME -> location L, name NAME.
path_location() { local p=${1#*/locations/}; echo "${p%%/*}"; }
h_redis() { del gcloud redis clusters delete "${1##*/}" --region "$(path_location "$1")" --project "$PROJECT"; }
h_run() { del gcloud run services delete "$1" --region "$2" --project "$PROJECT"; }
h_function() { del gcloud functions delete "${1##*/}" --v2 --region "$(path_location "$1")" --project "$PROJECT"; }
h_bucket() { del gcloud storage rm -r "gs://$1" --project "$PROJECT"; }
h_artifact() { del gcloud artifacts repositories delete "${1##*/}" --location "$(path_location "$1")" --project "$PROJECT"; }
h_secret() { del gcloud secrets delete "${1##*/}" --project "$PROJECT"; }
h_sink() { del gcloud logging sinks delete "$1" --project "$PROJECT"; }
h_sa() { del gcloud iam service-accounts delete "$1" --project "$PROJECT"; }
h_forwarding_rules() { compute_delete forwarding-rules "$1" "" "$3"; }
h_https_proxies() { compute_delete target-https-proxies "$1" "" "$3"; }
h_http_proxies() { compute_delete target-http-proxies "$1" "" "$3"; }
h_url_maps() { compute_delete url-maps "$1" "" "$3"; }
h_backend_services() { compute_delete backend-services "$1" "" "$3"; }
h_backend_buckets() { compute_delete backend-buckets "$1" "" ""; }
h_ssl_certs() { compute_delete ssl-certificates "$1" "" "$3"; }
h_negs() { compute_delete network-endpoint-groups "$1" "$2" "$3"; }
h_security_policies() { compute_delete security-policies "$1" "" "$3"; }
h_instances() { compute_delete instances "$1" "$2" ""; }
h_addresses() { compute_delete addresses "$1" "" "$3"; }
h_routers() { compute_delete routers "$1" "" "$3"; }
h_firewalls() { compute_delete firewall-rules "$1" "" ""; }
h_subnets() { del gcloud compute networks subnets delete "$1" --region "$3" --project "$PROJECT"; }
h_networks() { compute_delete networks "$1" "" ""; }

# Compute listings return name, zone and region; unused fields are empty.
CF='name,zone,region'

sweep "container clusters" "$FILTER" "name,location" h_gke gcloud container clusters list
sweep "sql instances" "$FILTER" "name" h_sql gcloud sql instances list
sweep "redis clusters" "$PATH_FILTER" "name" h_redis gcloud redis clusters list --region=-
sweep "run services" "metadata.labels.environment=test OR metadata.name~^olensys-test-" \
  "metadata.name,metadata.labels.'cloud.googleapis.com/location'" h_run gcloud run services list
sweep "functions" "$PATH_FILTER" "name" h_function gcloud functions list --v2
sweep "compute forwarding-rules" "$FILTER" "$CF" h_forwarding_rules gcloud compute forwarding-rules list
sweep "compute target-https-proxies" "$FILTER" "$CF" h_https_proxies gcloud compute target-https-proxies list
sweep "compute target-http-proxies" "$FILTER" "$CF" h_http_proxies gcloud compute target-http-proxies list
sweep "compute url-maps" "$FILTER" "$CF" h_url_maps gcloud compute url-maps list
sweep "compute backend-services" "$FILTER" "$CF" h_backend_services gcloud compute backend-services list
sweep "compute backend-buckets" "$FILTER" "$CF" h_backend_buckets gcloud compute backend-buckets list
sweep "compute ssl-certificates" "$FILTER" "$CF" h_ssl_certs gcloud compute ssl-certificates list
sweep "compute network-endpoint-groups" "$FILTER" "$CF" h_negs gcloud compute network-endpoint-groups list
sweep "compute security-policies" "$FILTER" "$CF" h_security_policies gcloud compute security-policies list
sweep "compute instances" "$FILTER" "$CF" h_instances gcloud compute instances list
sweep "compute addresses" "$FILTER" "$CF" h_addresses gcloud compute addresses list
sweep "compute routers" "$FILTER" "$CF" h_routers gcloud compute routers list
sweep "compute firewall-rules" "$FILTER" "$CF" h_firewalls gcloud compute firewall-rules list
sweep "compute networks subnets" "$FILTER" "$CF" h_subnets gcloud compute networks subnets list
sweep "compute networks" "$FILTER" "$CF" h_networks gcloud compute networks list
sweep "storage buckets" "$FILTER" "name" h_bucket gcloud storage buckets list
sweep "artifacts repositories" "$PATH_FILTER" "name" h_artifact gcloud artifacts repositories list
sweep "secrets" "$PATH_FILTER" "name" h_secret gcloud secrets list
sweep "logging sinks" "$FILTER" "name" h_sink gcloud logging sinks list
sweep "iam service-accounts" "email~^olensys-test- AND NOT email=$CI_SA" "email" h_sa gcloud iam service-accounts list

if [ "$FAILED" -gt 0 ]; then
  echo "$FAILED deletion(s) failed" >&2
  exit 1
fi
