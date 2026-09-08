#!/usr/bin/env bash
set -euo pipefail

soatest_script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$soatest_script_dir/../../workflow-config/scripts/load-orchestration-config.sh"
# shellcheck source=../../workflow-config/scripts/resolve-build-id.sh
source "$soatest_script_dir/../../workflow-config/scripts/resolve-build-id.sh"

usage() {
    cat <<'USAGE'
Usage:
  scripts/run-soatest.sh <local|ci|publish> [--resource <path>]...

Runs SOAtest resources with repository DTP and application-coverage settings.
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
            resources+=(-resource "$2")
            shift 2
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done
[[ ${#resources[@]} -gt 0 ]] || { echo 'At least one resource is required.' >&2; exit 2; }

if [[ "$preset" == publish ]]; then
    for variable in DTP_URL DTP_USER DTP_PASSWORD; do
        [[ -n "${!variable:-}" ]] || { echo "Missing required DTP value: $variable" >&2; exit 2; }
    done
fi

report_dir="${SOATEST_REPORT:-$REPORT_SOATEST_ROOT/soatest-$JTEST_BUILD_ID}"
mkdir -p "$report_dir"

soatest_args=(
    -server "$SOATEST_SERVER"
    -config "$SOATEST_CONFIG"
    -report "$report_dir"
    -property "build.id=$JTEST_BUILD_ID"
    -property 'session.tag=soatest'
    -property 'report.associations=true'
    -property 'application.coverage.enabled=true'
    -property "application.coverage.agent.url=http://localhost:${JTEST_AGENT_REST_PORT:-8050}"
    -property "application.coverage.images=$DTP_SOATEST_COVERAGE_IMAGES"
    "${resources[@]}"
)

if [[ "$preset" == publish ]]; then
    soatest_args+=(
        -publish
        -property 'dtp.enabled=true'
        -property "dtp.url=$DTP_URL"
        -property "dtp.user=$DTP_USER"
        -property "dtp.password=$DTP_PASSWORD"
        -property "dtp.project=$DTP_PROJECT"
        -property 'report.dtp.publish=true'
        -property 'application.coverage.dtp.publish=true'
    )
fi

"$soatest_script_dir/soatestcli.sh" "${soatest_args[@]}"