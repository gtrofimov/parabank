#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
config_dir="$repo_root/config"
legacy_root="$repo_root"

config_file="$config_dir/orchestration.config"
if [[ ! -f "$config_file" && -f "$legacy_root/orchestration.config" ]]; then
    config_file="$legacy_root/orchestration.config"
fi

env_file="$config_dir/.env"
if [[ ! -f "$env_file" && -f "$legacy_root/.env" ]]; then
    env_file="$legacy_root/.env"
fi

jtest_skills_config_file="$config_dir/jtest-skills.config"
if [[ ! -f "$jtest_skills_config_file" && -f "$legacy_root/jtest-skills.config" ]]; then
    jtest_skills_config_file="$legacy_root/jtest-skills.config"
fi

[[ -f "$config_file" ]] || { echo "Missing configuration: $config_file" >&2; exit 2; }

export CONFIG_DIR="$config_dir"
export ORCHESTRATION_CONFIG_FILE="$config_file"
export JTEST_SKILLS_CONFIG_FILE="$jtest_skills_config_file"
export ENV_FILE="$env_file"

# shellcheck source=/dev/null
source "$config_file"
if [[ -f "$env_file" ]]; then
    # shellcheck source=/dev/null
    source "$env_file"
fi

for variable in DTP_PROJECT DTP_UT_COVERAGE_IMAGES DTP_SOATEST_COVERAGE_IMAGES SOATEST_SERVER SOATEST_CONFIG \
    REPORT_ROOT REPORT_JTEST_ROOT REPORT_SOATEST_ROOT REPORT_APP_COVERAGE_ROOT \
    SOATEST_REPORT_ROOT JTEST_APP_COVERAGE_REPORT_ROOT CARGO_SERVLET_PORT CARGO_TOMCAT_HOME JTEST_MONITOR_HOME; do
    [[ -n "${!variable:-}" ]] || { echo "Missing required configuration: $variable" >&2; exit 2; }
    export "$variable"
done

export CONFIG_DIR ORCHESTRATION_CONFIG_FILE JTEST_SKILLS_CONFIG_FILE ENV_FILE

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
fi

for variable in DTP_PROJECT DTP_UT_COVERAGE_IMAGES DTP_SOATEST_COVERAGE_IMAGES SOATEST_SERVER SOATEST_CONFIG \
    REPORT_ROOT REPORT_JTEST_ROOT REPORT_SOATEST_ROOT REPORT_APP_COVERAGE_ROOT \
    SOATEST_REPORT_ROOT JTEST_APP_COVERAGE_REPORT_ROOT CARGO_SERVLET_PORT CARGO_TOMCAT_HOME JTEST_MONITOR_HOME; do
    printf 'export %s=%q\n' "$variable" "${!variable}"
done
printf 'export CONFIG_DIR=%q\n' "$config_dir"
printf 'export ORCHESTRATION_CONFIG_FILE=%q\n' "$config_file"
printf 'export JTEST_SKILLS_CONFIG_FILE=%q\n' "$jtest_skills_config_file"
printf 'export ENV_FILE=%q\n' "$env_file"