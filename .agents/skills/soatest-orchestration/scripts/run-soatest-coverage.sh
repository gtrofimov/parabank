#!/usr/bin/env bash
set -euo pipefail

soatest_script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$soatest_script_dir/../../workflow-config/scripts/load-orchestration-config.sh"

usage() {
    cat <<'USAGE'
Usage:
    scripts/run-soatest-coverage.sh <local|ci|publish> [--resource <path>]...

Compatibility wrapper for SOAtest execution. Application coverage calculation
is intentionally disabled; coverage is read from the Jtest unit-test report.
USAGE
}

preset="${1:-}"
if [[ -z "$preset" || "$preset" == '-h' || "$preset" == '--help' ]]; then
    usage
    exit 2
fi
shift
case "$preset" in
    local|ci|publish) ;;
    *) usage >&2; exit 2 ;;
esac

SOATEST_REPORT="${SOATEST_REPORT:-$REPORT_SOATEST_ROOT/application-coverage}" \
    "$soatest_script_dir/run-soatest.sh" "$preset" "$@"
