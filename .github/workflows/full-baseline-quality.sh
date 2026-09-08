#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_OUT="$REPO_ROOT/full_baseline_quality.txt"
VERIFY_OUT="$REPO_ROOT/full_baseline_quality_verify.txt"

ts() {
    echo "[$(date '+%H:%M:%S')] $*"
}

die() {
    echo "::error::$*" >&2
    exit 1
}

require_field() {
    local name="$1"
    grep -Eq "^${name}=" "$RUN_OUT" || {
        tail -80 "$RUN_OUT" || true
        die "Missing required output field: $name"
    }
}

: "${COPILOT_GITHUB_TOKEN:?Missing COPILOT_GITHUB_TOKEN}"
: "${QUALITY_RUN_KIND:=baseline}"
: "${QUALITY_PRESET:=publish}"
: "${SOATEST_HEALTH_RESOURCE:?Missing SOATEST_HEALTH_RESOURCE}"
: "${SOATEST_API_RESOURCES:?Missing SOATEST_API_RESOURCES}"
: "${SOATEST_MCP_AUTH_TOKEN:?Missing SOATEST_MCP_AUTH_TOKEN}"

# shellcheck source=/dev/null
source "$REPO_ROOT/.agents/skills/workflow-config/scripts/load-orchestration-config.sh"
SOATEST_URL="${SOATEST_URL:-$SOATEST_SERVER}"
SOATEST_MCP_URL="${SOATEST_URL%/}/soavirt/mcp"

case "$QUALITY_RUN_KIND" in
    baseline|feature) ;;
    *) die "QUALITY_RUN_KIND must be baseline or feature" ;;
esac

case "$QUALITY_PRESET" in
    ci|publish) ;;
    *) die "QUALITY_PRESET must be ci or publish" ;;
esac

for command_name in copilot envsubst timeout tee; do
    command -v "$command_name" >/dev/null || die "Required command not found: $command_name"
done

if [[ "$QUALITY_PRESET" == publish ]]; then
    for variable in DTP_URL DTP_USER DTP_PASSWORD; do
        [[ -n "${!variable:-}" ]] || die "Missing required publish value: $variable"
    done
fi

ts "Registering SOAtest MCP server..."
copilot mcp remove soatest-cicd >/dev/null 2>&1 || true
copilot mcp add \
    --transport http \
    --header "Authorization: Basic ${SOATEST_MCP_AUTH_TOKEN}" \
    soatest-cicd \
    "$SOATEST_MCP_URL"

ts "Running full baseline quality workflow..."
PROMPT=$(
    QUALITY_RUN_KIND="$QUALITY_RUN_KIND" \
    QUALITY_PRESET="$QUALITY_PRESET" \
    SOATEST_HEALTH_RESOURCE="$SOATEST_HEALTH_RESOURCE" \
    SOATEST_API_RESOURCES="$SOATEST_API_RESOURCES" \
    envsubst < "$SCRIPT_DIR/full-baseline-quality-prompt.md"
)
rm -f "$RUN_OUT"

set +e
(
    cd "$REPO_ROOT"
    timeout 4200 copilot --allow-all --no-ask-user -p "$PROMPT" < /dev/null | tee "$RUN_OUT"
)
run_exit=${PIPESTATUS[0]}
set -e

if [[ $run_exit -eq 124 ]]; then
    die "Full baseline quality workflow timed out"
fi
if [[ $run_exit -ne 0 ]]; then
    die "Full baseline quality workflow failed with exit code $run_exit"
fi

grep -Eq '^QUALITY_STATUS=passed[[:space:]]*$' "$RUN_OUT" || {
    tail -80 "$RUN_OUT" || true
    die "Missing QUALITY_STATUS=passed"
}

for field in BUILD_ID SA_STATUS SA_REPORT UT_STATUS UT_REPORT COVERAGE_STATUS COVERAGE_XML SOATEST_STATUS SOATEST_REPORT APP_COVERAGE_STATUS APP_COVERAGE_REPORT PARSER_PATH; do
    require_field "$field"
done

rm -f "$VERIFY_OUT"

get_field() {
    local name="$1"
    sed -n "s/^${name}=//p" "$RUN_OUT" | tail -n 1
}

for field in SA_REPORT UT_REPORT COVERAGE_XML SOATEST_REPORT; do
    report_path=$(get_field "$field")
    [[ -n "$report_path" && "$report_path" != '--' && -s "$REPO_ROOT/$report_path" ]] || {
        echo "EVIDENCE_STATUS=invalid" | tee "$VERIFY_OUT"
        die "Missing report artifact for $field: $report_path"
    }
done

coverage_xml=$(get_field COVERAGE_XML)
app_coverage_report=$(get_field APP_COVERAGE_REPORT)
[[ "$app_coverage_report" == "$coverage_xml" ]] || {
    echo "EVIDENCE_STATUS=invalid" | tee "$VERIFY_OUT"
    die "APP_COVERAGE_REPORT must match COVERAGE_XML"
}

printf 'EVIDENCE_STATUS=valid\n' | tee "$VERIFY_OUT"

ts "Full baseline quality workflow completed."
