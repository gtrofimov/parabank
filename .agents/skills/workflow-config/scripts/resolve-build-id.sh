#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=load-orchestration-config.sh
source "$script_dir/load-orchestration-config.sh"

if [[ -n "${JTEST_BUILD_ID:-}" ]]; then
    build_id="$JTEST_BUILD_ID"
elif [[ -n "${BUILD_NUMBER:-}" ]]; then
    build_id="${DTP_PROJECT}-${BUILD_NUMBER}"
    if [[ -n "${JIRA_ISSUE_KEY:-}" ]]; then
        build_id="${build_id}-${JIRA_ISSUE_KEY}"
    fi
else
    build_id="${DTP_PROJECT}-local-$(date -u +%Y%m%d)"
    if [[ -n "${JIRA_ISSUE_KEY:-}" ]]; then
        build_id="${build_id}-${JIRA_ISSUE_KEY}"
    fi
fi

JTEST_BUILD_ID="$build_id"
export JTEST_BUILD_ID

if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0
fi

printf 'export DTP_PROJECT=%q\nexport JTEST_BUILD_ID=%q\n' "$DTP_PROJECT" "$JTEST_BUILD_ID"