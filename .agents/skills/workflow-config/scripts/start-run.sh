#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"
script_dir="$repo_root/.agents/skills/workflow-config/scripts"
# shellcheck source=/dev/null
source "$script_dir/load-orchestration-config.sh"
# shellcheck source=/dev/null
source "$script_dir/resolve-build-id.sh"

run_dir="$repo_root/.orchestration/$JTEST_BUILD_ID"
mkdir -p "$run_dir"
manifest="$run_dir/manifest.env"
commit=$(git rev-parse HEAD)
branch=$(git branch --show-current)
config_hash=$(sha256sum "$ORCHESTRATION_CONFIG_FILE" "$JTEST_SETTINGS_FILE" "$JTEST_SKILLS_CONFIG_FILE" | sha256sum | awk '{print $1}')

if [[ -f "$manifest" ]]; then
    # shellcheck source=/dev/null
    source "$manifest"
    [[ "${RUN_COMMIT:-}" == "$commit" && "${RUN_BUILD_ID:-}" == "$JTEST_BUILD_ID" ]] || {
        echo "Existing run manifest belongs to another commit or build" >&2
        exit 2
    }
else
    cat > "$manifest" <<EOF
RUN_BUILD_ID=$(printf '%q' "$JTEST_BUILD_ID")
RUN_PROJECT=$(printf '%q' "$DTP_PROJECT")
RUN_BRANCH=$(printf '%q' "$branch")
RUN_COMMIT=$(printf '%q' "$commit")
RUN_CONFIG_HASH=$(printf '%q' "$config_hash")
RUN_STARTED_AT=$(printf '%q' "$(date -u +%Y-%m-%dT%H:%M:%SZ)")
EOF
fi

printf 'Run manifest: %s\n' "$manifest"