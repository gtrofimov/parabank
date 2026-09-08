#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

# shellcheck source=/dev/null
source "$repo_root/.agents/skills/workflow-config/scripts/load-orchestration-config.sh"

mode="${1:-publish}"
case "$mode" in
    baseline|feature|publish) ;;
    *) echo "Usage: $0 <baseline|feature|publish>" >&2; exit 2 ;;
esac

[[ -f "$JTEST_SETTINGS_FILE" ]] || {
    echo "Missing Jtest settings: $JTEST_SETTINGS_FILE" >&2
    exit 2
}
[[ -f "$JTEST_SKILLS_CONFIG_FILE" ]] || {
    echo "Missing Jtest policy config: $JTEST_SKILLS_CONFIG_FILE" >&2
    exit 2
}
command -v jtestcli >/dev/null || { echo "jtestcli not found" >&2; exit 2; }
command -v mvn >/dev/null || { echo "mvn not found" >&2; exit 2; }

for variable in DTP_URL DTP_USER DTP_PASSWORD; do
    [[ -n "${!variable:-}" ]] || {
        echo "Missing required publish value: $variable" >&2
        exit 2
    }
done

case "$mode" in
    baseline)
        [[ "$(git branch --show-current)" == "master" ]] || {
            echo "Baseline requires master branch" >&2
            exit 2
        }
        ;;
    feature)
        [[ "$(git branch --show-current)" != "master" ]] || {
            echo "Feature run cannot execute on master branch" >&2
            exit 2
        }
        ;;
esac

grep -q '^report\.coverage\.images=' "$JTEST_SETTINGS_FILE" || {
    echo "Missing report.coverage.images" >&2
    exit 2
}
grep -q '^report\.coverage\.static\.images=' "$JTEST_SETTINGS_FILE" || {
    echo "Missing report.coverage.static.images" >&2
    exit 2
}

printf 'Preflight passed: mode=%s branch=%s commit=%s project=%s\n' \
    "$mode" "$(git branch --show-current)" "$(git rev-parse --short HEAD)" "$DTP_PROJECT"