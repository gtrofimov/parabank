#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
script_dir="$repo_root/.agents/skills/workflow-config/scripts"
# shellcheck source=/dev/null
source "$script_dir/load-orchestration-config.sh"
# shellcheck source=/dev/null
source "$script_dir/resolve-build-id.sh"

mode="${1:-}"
config="${2:-}"
report_dir="${3:-}"
data_file="${4:-target/jtest/jtest.data.json}"
[[ "$mode" == sa || "$mode" == ut ]] || { echo "Usage: $0 <sa|ut> <config> <report-dir> [data-file]" >&2; exit 2; }
[[ -n "$config" && -n "$report_dir" ]] || { echo "Missing config or report directory" >&2; exit 2; }

branch_mode=feature
[[ "$(git branch --show-current)" == master ]] && branch_mode=baseline
"$script_dir/preflight.sh" "$branch_mode"
"$script_dir/start-run.sh"
"$script_dir/validate-jtest-data.sh" "$mode" "$data_file"
[[ ! -e "$report_dir" || -z "$(find "$report_dir" -mindepth 1 -print -quit 2>/dev/null)" ]] || {
    echo "Report directory is not empty: $report_dir" >&2
    exit 2
}
mkdir -p "$report_dir"

jtestcli -data "$data_file" \
    -config "$config" -report "$report_dir" -publish \
    -property "build.id=$JTEST_BUILD_ID" \
    -property "dtp.project=$DTP_PROJECT" \
    -property "report.coverage.images=$DTP_UT_COVERAGE_IMAGES" \
    -property "report.coverage.static.images=$DTP_SOATEST_COVERAGE_IMAGES" \
    -property 'report.associations=true' \
    -property 'report.scontrol=full' \
    -property 'report.dtp.publish.src=full' \
    -property 'scope.local=true' \
    -property 'scope.xmlmap=false' \
    -property "dtp.url=$DTP_URL" \
    -property "dtp.user=$DTP_USER" \
    -property "dtp.password=$DTP_PASSWORD"

"$script_dir/validate-jtest-report.sh" "$mode" "$report_dir"
touch ".orchestration/$JTEST_BUILD_ID/$mode.published"