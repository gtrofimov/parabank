#!/usr/bin/env bash
# Registers the Atlassian/Jira MCP server for non-interactive (CI) copilot
# runs. Interactive VS Code sessions already have this MCP server configured
# globally and do not need this script.
set -euo pipefail

: "${ROVO_EMAIL:?Missing ROVO_EMAIL}"
: "${ROVO_TOKEN:?Missing ROVO_TOKEN}"

atlassian_base_url="${ATLASSIAN_BASE_URL:-https://parasoft-demo.atlassian.net}"
basic_auth=$(printf '%s:%s' "$ROVO_EMAIL" "$ROVO_TOKEN" | base64 | tr -d '\n')

command -v copilot >/dev/null || { echo "copilot CLI not found" >&2; exit 2; }

copilot mcp remove jira-remote-cicd >/dev/null 2>&1 || true
copilot mcp add \
    --transport http \
    --header "Authorization: Basic ${basic_auth}" \
    --env "ATLASSIAN_BASE_URL=${atlassian_base_url}" \
    jira-remote-cicd \
    https://mcp.atlassian.com/v1/mcp

echo "Registered jira-remote-cicd MCP server for ${atlassian_base_url}"
