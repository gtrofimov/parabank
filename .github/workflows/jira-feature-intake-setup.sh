#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ts() {
    echo "[$(date '+%H:%M:%S')] $*"
}

: "${ROVO_EMAIL:?Missing ROVO_EMAIL}"
: "${ROVO_TOKEN:?Missing ROVO_TOKEN}"

if [[ -z "${JTEST_REFERENCE_BRANCH:-}" && -f "$REPO_ROOT/config/jtest-skills.config" ]]; then
    JTEST_REFERENCE_BRANCH="$(sed -n 's/^JTEST_REFERENCE_BRANCH=//p' "$REPO_ROOT/config/jtest-skills.config" | tail -1)"
fi
export JTEST_REFERENCE_BRANCH="${JTEST_REFERENCE_BRANCH:-master}"
if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "JTEST_REFERENCE_BRANCH=${JTEST_REFERENCE_BRANCH}" >> "$GITHUB_ENV"
fi

command -v copilot >/dev/null || { echo "copilot CLI not found" >&2; exit 2; }

ts "Registering Jira MCP server..."
"$REPO_ROOT/.agents/skills/jira-feature-intake/scripts/register-jira-mcp.sh"

if [[ -n "${SOATEST_MCP_AUTH_TOKEN:-}" ]]; then
    ts "Registering SOAtest MCP server..."
    # shellcheck source=/dev/null
    source "$REPO_ROOT/.agents/skills/workflow-config/scripts/load-orchestration-config.sh"
    SOATEST_URL="${SOATEST_URL:-$SOATEST_SERVER}"
    SOATEST_MCP_URL="${SOATEST_URL%/}/soavirt/mcp"
    copilot mcp remove soatest-cicd >/dev/null 2>&1 || true
    copilot mcp add \
        --transport http \
        --header "Authorization: Basic ${SOATEST_MCP_AUTH_TOKEN}" \
        soatest-cicd \
        "$SOATEST_MCP_URL" || true
fi

if [[ -n "${DTP_URL:-}" && -n "${DTP_USER:-}" && -n "${DTP_PASSWORD:-}" ]]; then
    ts "Registering DTP MCP server..."
    dtp_basic_auth=$(printf '%s:%s' "$DTP_USER" "$DTP_PASSWORD" | base64 | tr -d '\n')
    copilot mcp remove dtp-cicd >/dev/null 2>&1 || true
    copilot mcp add \
        --transport sse \
        --header "Authorization: Basic ${dtp_basic_auth}" \
        dtp-cicd \
        "${DTP_URL%/}/grs/mcp/sse" || true
else
    ts "DTP MCP credentials unavailable; Verify will use available report evidence only."
fi

jtest_mcp_command="${JTEST_MCP_COMMAND:-${JTEST_HOME:-}/integration/mcp/jtestmcp}"
[[ -x "$jtest_mcp_command" ]] || {
    echo "MCP_ERROR: Jtest MCP executable unavailable: $jtest_mcp_command" >&2
    exit 2
}
ts "Registering mandatory Jtest MCP server..."
copilot mcp remove jtest-cicd >/dev/null 2>&1 || true
copilot mcp add \
    --transport stdio \
    jtest-cicd \
    -- \
    "$jtest_mcp_command"

ts "MCP servers registered."
