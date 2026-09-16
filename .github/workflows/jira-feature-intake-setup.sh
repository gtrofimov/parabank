#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

ts() {
    echo "[$(date '+%H:%M:%S')] $*"
}

: "${ROVO_EMAIL:?Missing ROVO_EMAIL}"
: "${ROVO_TOKEN:?Missing ROVO_TOKEN}"

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

ts "MCP servers registered."
