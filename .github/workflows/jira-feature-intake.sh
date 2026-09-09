#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_OUT="/tmp/jira_feature_intake.txt"

ts() {
    echo "[$(date '+%H:%M:%S')] $*"
}

die() {
    echo "::error::$*" >&2
    exit 1
}

: "${COPILOT_GITHUB_TOKEN:?Missing COPILOT_GITHUB_TOKEN}"
: "${ROVO_EMAIL:?Missing ROVO_EMAIL}"
: "${ROVO_TOKEN:?Missing ROVO_TOKEN}"
: "${JIRA_TICKET:?Missing JIRA_TICKET}"

for command_name in copilot envsubst; do
    command -v "$command_name" >/dev/null || die "Required command not found: $command_name"
done

ts "Registering Jira MCP server..."
"$REPO_ROOT/.agents/skills/jira-feature-intake/scripts/register-jira-mcp.sh"

ts "Running Jira feature intake for ${JIRA_TICKET}..."
PROMPT=$(JIRA_TICKET="${JIRA_TICKET}" envsubst < "$SCRIPT_DIR/jira-feature-intake-prompt.md")
rm -f "$RUN_OUT"

set +e
(
    cd "$REPO_ROOT"
    timeout 2700 copilot --allow-all --no-ask-user -p "$PROMPT" < /dev/null | tee "$RUN_OUT"
)
run_exit=${PIPESTATUS[0]}
set -e

if grep -q "^MCP_ERROR:" "$RUN_OUT" 2>/dev/null; then
    grep "^MCP_ERROR:" "$RUN_OUT"
    die "Agent reported MCP tool unavailability"
fi
if [[ $run_exit -eq 124 ]]; then
    die "Jira feature intake timed out after 2700s"
fi
if [[ $run_exit -ne 0 ]]; then
    die "Jira feature intake failed with exit code $run_exit"
fi

for field in JIRA_ISSUE BRANCH BUILD_ID FEATURE_PROMPT TEST_PLAN PR_URL; do
    grep -Eq "^\`?${field}=[^\`]+\`?[[:space:]]*\$" "$RUN_OUT" || {
        tail -40 "$RUN_OUT" || true
        die "Missing ${field} in jira_feature_intake.txt"
    }
done

branch="$(grep -E '^`?BRANCH=' "$RUN_OUT" | tail -1 | sed -E 's/^`?BRANCH=//; s/`?[[:space:]]*$//')"
git -C "$REPO_ROOT" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 || {
    die "Branch ${branch} was not found on origin after the run"
}

cp "$RUN_OUT" "$REPO_ROOT/jira_feature_intake.txt" || true

ts "Jira feature intake complete: branch=${branch}"
