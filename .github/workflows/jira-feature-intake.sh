#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PHASE="${1:?Usage: jira-feature-intake.sh <plan|act|verify>}"
PROMPT_FILE="$SCRIPT_DIR/jira-feature-intake-${PHASE}-prompt.md"
RUN_OUT="/tmp/jira_feature_intake_${PHASE}.txt"

ts() {
    echo "[$(date '+%H:%M:%S')] $*"
}

die() {
    echo "::error::$*" >&2
    exit 1
}

: "${COPILOT_GITHUB_TOKEN:?Missing COPILOT_GITHUB_TOKEN}"
: "${JIRA_TICKET:?Missing JIRA_TICKET}"
: "${GITHUB_ENV:?Missing GITHUB_ENV}"
[[ -f "$PROMPT_FILE" ]] || die "Unknown phase '${PHASE}' (no prompt file at ${PROMPT_FILE})"

for command_name in copilot envsubst; do
    command -v "$command_name" >/dev/null || die "Required command not found: $command_name"
done

extract() {
    grep -E "^\`?${1}=[^\`]+\`?[[:space:]]*\$" "$RUN_OUT" | tail -1 | sed -E "s/^\`?${1}=//; s/\`?[[:space:]]*\$//"
}

require_field() {
    local value
    value="$(extract "$1")"
    [[ -n "$value" ]] || { tail -40 "$RUN_OUT" || true; die "Missing ${1} in phase '${PHASE}' output"; }
    printf '%s' "$value"
}

ts "Running Jira feature intake phase '${PHASE}' for ${JIRA_TICKET}..."
PROMPT=$(JIRA_TICKET="${JIRA_TICKET}" envsubst < "$PROMPT_FILE")
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
    die "Agent reported MCP tool unavailability in phase '${PHASE}'"
fi
if [[ $run_exit -eq 124 ]]; then
    die "Jira feature intake phase '${PHASE}' timed out after 2700s"
fi
if [[ $run_exit -ne 0 ]]; then
    die "Jira feature intake phase '${PHASE}' failed with exit code $run_exit"
fi

case "$PHASE" in
    plan)
        jira_issue="$(require_field JIRA_ISSUE)"
        branch="$(require_field BRANCH)"
        feature_prompt="$(require_field FEATURE_PROMPT)"
        test_plan="$(require_field TEST_PLAN)"
        {
            echo "JIRA_ISSUE=${jira_issue}"
            echo "BRANCH=${branch}"
            echo "FEATURE_PROMPT=${feature_prompt}"
            echo "TEST_PLAN=${test_plan}"
        } >>"$GITHUB_ENV"
        ts "Plan complete: issue=${jira_issue} branch=${branch}"
        ;;
    act)
        require_field ACT_STATUS >/dev/null
        ts "Act complete."
        ;;
    verify)
        pr_url="$(require_field PR_URL)"
        branch="${BRANCH:?Missing BRANCH env var}"
        git -C "$REPO_ROOT" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 || {
            die "Branch ${branch} was not found on origin after the verify phase"
        }
        echo "PR_URL=${pr_url}" >>"$GITHUB_ENV"
        ts "Verify complete: PR=${pr_url}"
        ;;
    *)
        die "Unknown phase: ${PHASE}"
        ;;
esac

cp "$RUN_OUT" "$REPO_ROOT/jira_feature_intake_${PHASE}.txt" || true
