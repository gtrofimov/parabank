#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$script_dir/../../workflow-config/scripts/load-orchestration-config.sh"

coverage_dir="${1:-$JTEST_MONITOR_HOME}"
[[ -n "$coverage_dir" ]] || { echo "Usage: $0 <application-coverage-dir>" >&2; exit 2; }

monitor_archive='target/jtest/monitor/monitor.zip'
[[ -f "$monitor_archive" ]] || {
    echo "Jtest monitor artifact missing: $monitor_archive. Run the UT build before monitor deployment." >&2
    exit 2
}
for monitor_file in monitor/agent.jar monitor/agent.properties monitor/static_coverage.xml; do
    unzip -Z1 "$monitor_archive" | grep -Fxq "$monitor_file" || {
        echo "Jtest monitor artifact is incomplete: missing $monitor_file in $monitor_archive" >&2
        exit 2
    }
done
[[ -d "$coverage_dir" ]] || { echo "Application coverage directory not found: $coverage_dir" >&2; exit 2; }
coverage_dir=$(cd "$coverage_dir" && pwd)

monitor_dir="$coverage_dir/monitor"
runtime_dir="$monitor_dir/runtime_coverage"
rm -rf "$monitor_dir"
unzip -oq "$monitor_archive" -d "$coverage_dir"

printf 'export JTEST_MONITOR_JVM_ARGS=%q\n' \
    "-javaagent:${monitor_dir}/agent.jar=settings=${monitor_dir}/agent.properties,runtimeData=${runtime_dir}"