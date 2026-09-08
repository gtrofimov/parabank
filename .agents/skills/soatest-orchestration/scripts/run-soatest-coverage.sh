#!/usr/bin/env bash
set -euo pipefail

soatest_script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$soatest_script_dir/../../workflow-config/scripts/load-orchestration-config.sh"

usage() {
    cat <<'USAGE'
Usage:
    scripts/run-soatest-coverage.sh <local|ci|publish> [--resource <path>]...

Runs SOAtest against the monitor-instrumented Docker deployment and calculates
Jtest application coverage from monitor data copied out of the running
container. Run deploy-parabank-docker.sh before this command.
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

report_dir="${JTEST_APP_COVERAGE_REPORT:-$REPORT_APP_COVERAGE_ROOT}"
docker_container="${PARABANK_DOCKER_CONTAINER:-parabank-parabank-1}"
coverage_dir=target/jtest/docker-monitor
monitor_dir="$coverage_dir/monitor"
runtime_dir="$monitor_dir/runtime_coverage"

command -v docker >/dev/null || { echo 'docker not found' >&2; exit 2; }
if ! docker inspect "$docker_container" >/dev/null 2>&1; then
    echo "No running Docker container found for monitor copy: $docker_container" >&2
    echo "Run deploy-parabank-docker.sh before run-soatest-coverage.sh." >&2
    exit 2
fi
# shellcheck source=../../workflow-config/scripts/resolve-build-id.sh
source "$soatest_script_dir/../../workflow-config/scripts/resolve-build-id.sh"

coverage_args=(
    -config "builtin://Calculate Application Coverage"
    -staticcoverage "$monitor_dir/static_coverage.xml"
    -runtimecoverage "$runtime_dir"
    -property "build.id=$JTEST_BUILD_ID"
    -property "dtp.project=$DTP_PROJECT"
    -property "report.coverage.static.images=$DTP_SOATEST_COVERAGE_IMAGES"
    -property 'report.associations=true'
    -property 'report.scontrol=full'
    -property 'scope.local=true'
    -property 'scope.xmlmap=false'
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

rm -rf "$coverage_dir"
mkdir -p "$coverage_dir"
docker cp "$docker_container:/usr/local/tomcat/monitor" "$monitor_dir"

[[ -f "$monitor_dir/static_coverage.xml" && -d "$runtime_dir" ]] || {
    echo "Jtest monitor coverage data not found under: $monitor_dir" >&2
    exit 2
}

jtestcli "${coverage_args[@]}"
