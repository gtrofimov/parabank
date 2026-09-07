#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$script_dir/../../workflow-config/scripts/load-orchestration-config.sh"

coverage_dir="${1:-$JTEST_MONITOR_HOME}"
[[ -n "$coverage_dir" ]] || { echo "Usage: $0 <application-coverage-dir>" >&2; exit 2; }
[[ -d "$coverage_dir" ]] || { echo "Application coverage directory not found: $coverage_dir" >&2; exit 2; }
coverage_dir=$(cd "$coverage_dir" && pwd)

monitor_dir="$coverage_dir/monitor"
runtime_dir="$monitor_dir/runtime_coverage"
mvn package jtest:monitor -DskipTests >&2
rm -rf "$monitor_dir"
unzip -oq target/jtest/monitor/monitor.zip -d "$coverage_dir"

printf 'export JTEST_MONITOR_JVM_ARGS=%q\n' \
    "-javaagent:${monitor_dir}/agent.jar=settings=${monitor_dir}/agent.properties,runtimeData=${runtime_dir}"