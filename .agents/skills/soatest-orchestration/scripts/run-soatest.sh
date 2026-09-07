#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$script_dir/../../workflow-config/scripts/load-orchestration-config.sh"

usage() {
    cat <<'USAGE'
Usage:
  scripts/run-soatest.sh <preset> [--resource <path>]... [-- <extra args>]

Presets:
  local    Run tests locally (no fail gate, no publish)
  ci       Run tests with fail gate enabled
  publish  Run tests with publish enabled

Environment variables:
  SOATEST_SERVER       Default: https://localhost:9443
  SOATEST_AUTH         Optional USER:PASS
  SOATEST_CONFIG       Default: soatest.builtin://Demo Configuration
  SOATEST_ENV          Optional environment name
  SOATEST_REPORT       Default: ./reports/soatest
  SOATEST_PUBLISH      Optional override (true/false)
  SOATEST_FAIL         Optional override (true/false)
USAGE
}

json_value() {
    local property="$1"
    sed -n "s/.*\"${property}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

PRESET="${1:-}"
if [[ -z "$PRESET" || "$PRESET" == "-h" || "$PRESET" == "--help" ]]; then
    usage
    exit 0
fi
shift

PUBLISH_FLAG=false
FAIL_FLAG=false
case "$PRESET" in
    local) ;;
    ci) FAIL_FLAG=true ;;
    publish) PUBLISH_FLAG=true ;;
    *)
        echo "Unknown preset: $PRESET" >&2
        usage >&2
        exit 2
        ;;
esac

SERVER="$SOATEST_SERVER"
AUTH="${SOATEST_AUTH:-}"
CONFIG="$SOATEST_CONFIG"
ENV_NAME="${SOATEST_ENV:-}"
REPORT="${SOATEST_REPORT:-$SOATEST_REPORT_ROOT}"
PUBLISH_FLAG="${SOATEST_PUBLISH:-$PUBLISH_FLAG}"
FAIL_FLAG="${SOATEST_FAIL:-$FAIL_FLAG}"
RESOURCES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --resource|-resource)
            [[ $# -gt 1 ]] || { echo "Missing value for $1" >&2; exit 2; }
            RESOURCES+=("$2")
            shift 2
            ;;
        --)
            break
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

CURL_ARGS=(-sSfk -H 'Accept: application/json' --connect-timeout 30)
if [[ -n "$AUTH" ]]; then
    CURL_ARGS+=(-u "$AUTH")
fi

resource_json=''
for resource in "${RESOURCES[@]}"; do
    resource_json+="\"${resource//\"/\\\"}\","
done
resource_json="${resource_json%,}"
workspace_json='{}'
if [[ -n "$resource_json" ]]; then
    workspace_json="{\"resources\":[${resource_json}]}"
fi
environment_json=''
if [[ -n "$ENV_NAME" ]]; then
    environment_json=",\"soatestOptions\":{\"environment\":\"${ENV_NAME//\"/\\\"}\"}"
fi
request="{\"general\":{\"config\":\"${CONFIG//\"/\\\"}\",\"publish\":${PUBLISH_FLAG}},\"scopeOptions\":{\"workspace\":${workspace_json}}${environment_json}}"

echo "Checking server status: $SERVER"
curl "${CURL_ARGS[@]}" "$SERVER/soavirt/api/v5/status" >/dev/null

response=$(curl "${CURL_ARGS[@]}" -H 'Content-Type: application/json' -X POST -d "$request" "$SERVER/soavirt/api/v5/testExecutions")
job_id=$(printf '%s' "$response" | json_value id)
[[ -n "$job_id" ]] || { echo "Test execution did not return a job ID." >&2; exit 1; }
printf 'Test execution submitted with job ID %s\n' "$job_id"

while true; do
    status=$(curl "${CURL_ARGS[@]}" "$SERVER/soavirt/api/v5/testExecutions/${job_id}/status")
    is_running=$(printf '%s' "$status" | sed -n 's/.*"isRunning"[[:space:]]*:[[:space:]]*\(true\|false\).*/\1/p')
    percent=$(printf '%s' "$status" | sed -n 's/.*"percent"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
    [[ -n "$is_running" && -n "$percent" ]] || { echo "Invalid execution status response." >&2; exit 1; }
    printf '%s%%\n' "$percent"
    [[ "$is_running" == false && "$percent" == 100 ]] && break
    sleep 0.5
done

echo 'Retrieving test results'
results=$(curl "${CURL_ARGS[@]}" "$SERVER/soavirt/api/v5/testExecutions/${job_id}/results?includeReportArchive=true&includeHtmlReport=true&includeXmlReport=true")
failures=$(printf '%s' "$results" | sed -n 's/.*"failureCount"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
total=$(printf '%s' "$results" | sed -n 's/.*"testRunCount"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p')
printf 'Test results summary (failures/total): %s/%s\n' "${failures:-0}" "${total:-0}"

mkdir -p "$REPORT"
archive=$(printf '%s' "$results" | json_value reportArchive)
if [[ -n "$archive" ]]; then
    printf '%s' "$archive" | base64 -d > "$REPORT/archive.zip"
    unzip -oq "$REPORT/archive.zip" -d "$REPORT"
else
    xml_report=$(printf '%s' "$results" | json_value xmlReport)
    html_report=$(printf '%s' "$results" | json_value htmlReport)
    [[ -z "$xml_report" ]] || printf '%s' "$xml_report" | base64 -d > "$REPORT/report.xml"
    [[ -z "$html_report" ]] || printf '%s' "$html_report" | base64 -d > "$REPORT/report.html"
fi

if [[ "$FAIL_FLAG" == true && "${failures:-0}" -gt 0 ]]; then
    exit 4
fi