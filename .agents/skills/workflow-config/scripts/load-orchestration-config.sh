#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
config_file="$repo_root/orchestration.config"
env_file="$repo_root/.env"

[[ -f "$config_file" ]] || { echo "Missing configuration: $config_file" >&2; exit 2; }

# shellcheck source=/dev/null
source "$config_file"
if [[ -f "$env_file" ]]; then
    # shellcheck source=/dev/null
    source "$env_file"
fi

for variable in DTP_PROJECT SOATEST_SERVER SOATEST_CONFIG \
    SOATEST_REPORT_ROOT JTEST_APP_COVERAGE_REPORT_ROOT CARGO_SERVLET_PORT CARGO_TOMCAT_HOME JTEST_MONITOR_HOME; do
    [[ -n "${!variable:-}" ]] || { echo "Missing required configuration: $variable" >&2; exit 2; }
done

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
fi

for variable in DTP_PROJECT SOATEST_SERVER SOATEST_CONFIG \
    SOATEST_REPORT_ROOT JTEST_APP_COVERAGE_REPORT_ROOT CARGO_SERVLET_PORT CARGO_TOMCAT_HOME JTEST_MONITOR_HOME; do
    printf 'export %s=%q\n' "$variable" "${!variable}"
done