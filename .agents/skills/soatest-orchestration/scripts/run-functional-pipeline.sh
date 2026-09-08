#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage:
  scripts/run-functional-pipeline.sh <local|ci|publish> --health <scenario> --resource <scenario> [--resource <scenario>]...

Starts monitor-instrumented Cargo Tomcat, runs SOAtest health scenario first, then
runs API scenarios and calculates Jtest application coverage. `publish` publishes
coverage to DTP; CI must provide DTP_URL, DTP_USER, DTP_PASSWORD, and BUILD_NUMBER.
USAGE
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$script_dir/../../workflow-config/scripts/load-orchestration-config.sh"
# shellcheck source=../../workflow-config/scripts/resolve-build-id.sh
source "$script_dir/../../workflow-config/scripts/resolve-build-id.sh"

preset="${1:-}"
[[ -n "$preset" ]] || { usage >&2; exit 2; }
shift
case "$preset" in
    local|ci|publish) ;;
    *) usage >&2; exit 2 ;;
esac

health_resource=''
resources=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --health)
            [[ $# -gt 1 ]] || { echo 'Missing health scenario.' >&2; exit 2; }
            health_resource="$2"
            shift 2
            ;;
        --resource)
            [[ $# -gt 1 ]] || { echo 'Missing API scenario.' >&2; exit 2; }
            resources+=(--resource "$2")
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done
[[ -n "$health_resource" && ${#resources[@]} -gt 0 ]] || { usage >&2; exit 2; }

eval "$($script_dir/prepare-jtest-monitor.sh)"
log_file="${SOATEST_REPORT_ROOT}/cargo-${JTEST_BUILD_ID}.log"
mkdir -p "$(dirname "$log_file")"
mvn cargo:run -DskipTests -Dcargo.servlet.port="$CARGO_SERVLET_PORT" \
    -Dcargo.jvmargs="$JTEST_MONITOR_JVM_ARGS" >"$log_file" 2>&1 &
cargo_pid=$!
cleanup() {
    kill "$cargo_pid" 2>/dev/null || true
    mvn cargo:stop -Dcargo.servlet.port="$CARGO_SERVLET_PORT" >/dev/null 2>&1 || true
}
trap cleanup EXIT

curl -fsS --retry 30 --retry-connrefused --max-time 5 \
    "http://localhost:${CARGO_SERVLET_PORT}/parabank/" >/dev/null

SOATEST_REPORT="$SOATEST_REPORT_ROOT/health-$JTEST_BUILD_ID" \
    "$script_dir/run-soatest.sh" ci --resource "$health_resource"
SOATEST_REPORT="$SOATEST_REPORT_ROOT/api-$JTEST_BUILD_ID" \
    "$script_dir/run-soatest-coverage.sh" "$preset" "$JTEST_MONITOR_HOME" "${resources[@]}"