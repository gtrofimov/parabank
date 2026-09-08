#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/../../../.." && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$script_dir/../../workflow-config/scripts/load-orchestration-config.sh"
cd "$repo_root"

compose_project='parabank'
fresh=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fresh)
            fresh=true
            shift
            ;;
        *)
            echo "Usage: $0 [--fresh]" >&2
            exit 2
            ;;
    esac
done

compose=(docker compose --project-name "$compose_project" -f compose.parabank.yml)

if [[ "$fresh" == true ]]; then
    "${compose[@]}" down --volumes --remove-orphans
fi

# build-jtest-monitor.sh produces target/parabank-5.0.0-SNAPSHOT.war and
# target/jtest/monitor/monitor.zip, both baked into the image by Dockerfile.monitor.
.agents/skills/soatest-orchestration/scripts/build-jtest-monitor.sh

war_file=$(find target -maxdepth 1 -name '*.war' ! -name 'parabank.war' -print -quit)
[[ -n "$war_file" ]] || { echo "Built war not found under target/" >&2; exit 2; }
cp -f "$war_file" target/parabank.war

"${compose[@]}" up -d --build --remove-orphans

echo "Waiting for ParaBank to become healthy on port ${PARABANK_SERVLET_PORT}..."
curl -fsS --retry 30 --retry-connrefused --max-time 5 \
    "http://localhost:${PARABANK_SERVLET_PORT}/parabank/" >/dev/null

curl -fsS --retry 10 --retry-connrefused --max-time 5 \
    "http://localhost:${JTEST_AGENT_REST_PORT}/status" >/dev/null

echo "ParaBank is up on ${PARABANK_SERVLET_PORT}; Jtest monitor agent REST is up on ${JTEST_AGENT_REST_PORT}."
