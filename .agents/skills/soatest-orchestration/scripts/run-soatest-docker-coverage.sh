#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$script_dir/../../workflow-config/scripts/load-orchestration-config.sh"
# shellcheck source=../../workflow-config/scripts/resolve-build-id.sh
source "$script_dir/../../workflow-config/scripts/resolve-build-id.sh"

usage() {
    cat <<'USAGE'
Usage:
  scripts/run-soatest-docker-coverage.sh <local|ci|publish> [--resource <path>]...

Runs SOAtest against the monitor-instrumented Docker deployment and calculates
Jtest application coverage from monitor data copied out of the running container.
Run deploy-parabank-docker.sh before this command.
USAGE
}

preset="${1:-}"
[[ -n "$preset" ]] || { usage >&2; exit 2; }
shift
case "$preset" in
    local|ci|publish) ;;
    *) usage >&2; exit 2 ;;
esac

resources=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --resource)
            [[ $# -gt 1 ]] || { echo 'Missing resource path.' >&2; exit 2; }
            resources+=(--resource "$2")
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done
[[ ${#resources[@]} -gt 0 ]] || { echo 'At least one resource is required.' >&2; exit 2; }

container_name="${PARABANK_DOCKER_CONTAINER:-parabank-parabank-1}"
docker inspect "$container_name" >/dev/null

soatest_preset="${SOATEST_TEST_PRESET:-$preset}"
if [[ "$preset" == publish && -z "${SOATEST_TEST_PRESET:-}" ]]; then
    soatest_preset=ci
fi
SOATEST_REPORT="${SOATEST_REPORT:-$REPORT_SOATEST_ROOT/application-coverage}" \
    "$script_dir/run-soatest.sh" "$soatest_preset" "${resources[@]}"

coverage_dir="target/jtest/docker-monitor"
rm -rf "$coverage_dir"
mkdir -p "$coverage_dir"
docker cp "$container_name:/usr/local/tomcat/monitor" "$coverage_dir/monitor"

monitor_dir="$coverage_dir/monitor"
runtime_dir="$monitor_dir/runtime_coverage"
[[ -f "$monitor_dir/static_coverage.xml" && -d "$runtime_dir" ]] || {
    echo "Docker monitor coverage data was not copied from $container_name" >&2
    exit 2
}

report_dir="${JTEST_APP_COVERAGE_REPORT:-$REPORT_APP_COVERAGE_ROOT}"
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
if [[ "$preset" == publish ]]; then
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

jtestcli "${coverage_args[@]}"
