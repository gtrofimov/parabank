#!/usr/bin/env bash
set -euo pipefail

soatest_script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$soatest_script_dir/../../workflow-config/scripts/load-orchestration-config.sh"

usage() {
    cat <<'USAGE'
Usage:
  scripts/run-soatest-coverage.sh <local|ci|publish> <application-coverage-dir> [--resource <path>]...

Runs SOAtest and calculates Jtest application coverage. Before this command, run
prepare-jtest-monitor.sh and start app server with emitted JTEST_MONITOR_JVM_ARGS.
`application-coverage-dir` must be monitor deployment directory in app-server runtime.
USAGE
}

preset="${1:-}"
coverage_dir="${2:-$JTEST_MONITOR_HOME}"
if [[ -z "$preset" || -z "$coverage_dir" || "$preset" == '-h' || "$preset" == '--help' ]]; then
    usage
    exit 2
fi
shift 2
case "$preset" in
    local|ci|publish) ;;
    *) usage >&2; exit 2 ;;
esac

[[ -d "$coverage_dir" ]] || { echo "Application coverage directory not found: $coverage_dir" >&2; exit 2; }
monitor_dir="$coverage_dir/monitor"
runtime_dir="$monitor_dir/runtime_coverage"
report_dir="${JTEST_APP_COVERAGE_REPORT:-$REPORT_APP_COVERAGE_ROOT}"
[[ -f "$monitor_dir/agent.jar" && -f "$monitor_dir/static_coverage.xml" ]] || {
    echo "Jtest monitor missing. Run prepare-jtest-monitor.sh before starting application server." >&2
    exit 2
}
# shellcheck source=../../workflow-config/scripts/resolve-build-id.sh
source "$soatest_script_dir/../../workflow-config/scripts/resolve-build-id.sh"

coverage_args=(
    -config "builtin://Calculate Application Coverage"
    -staticcoverage "$monitor_dir/static_coverage.xml"
    -runtimecoverage "$runtime_dir"
    -settings "$JTEST_SETTINGS_FILE"
    -property "build.id=$JTEST_BUILD_ID"
    -property "dtp.project=$DTP_PROJECT"
    -report "$report_dir"
)
if [[ "$preset" == 'publish' ]]; then
    for variable in DTP_URL DTP_USER DTP_PASSWORD; do
        [[ -n "${!variable:-}" ]] || { echo "Missing required DTP publish value: $variable" >&2; exit 2; }
    done
    coverage_args+=(
        -publish
        -property "dtp.url=$DTP_URL"
        -property "dtp.user=$DTP_USER"
        -property "dtp.password=$DTP_PASSWORD"
    )
fi

soatest_preset="${SOATEST_TEST_PRESET:-$preset}"
if [[ "$preset" == 'publish' && -z "${SOATEST_TEST_PRESET:-}" ]]; then
    soatest_preset='ci'
fi
SOATEST_REPORT="${SOATEST_REPORT:-$REPORT_SOATEST_ROOT/application-coverage}" \
    "$soatest_script_dir/run-soatest.sh" "$soatest_preset" "$@"
jtestcli "${coverage_args[@]}"