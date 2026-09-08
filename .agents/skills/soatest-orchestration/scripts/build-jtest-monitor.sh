#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$script_dir/../../workflow-config/scripts/load-orchestration-config.sh"

# Builds target/jtest/monitor/monitor.zip from compiled classes.
# - report.coverage.static.images (from JTEST_SETTINGS_FILE) tags the packaged
#   static_coverage.xml/agent settings with the DTP_SOATEST_COVERAGE_IMAGES set
#   (default: Parabank_All;Parabank_SOAtest).
# - agentServerEnabled exposes the agent's own REST status/control port
#   (default 8050), separate from the deployed application's HTTP port.
mvn package jtest:monitor -DskipTests \
    -Djtest.settings="$JTEST_SETTINGS_FILE" \
    -Djtest.agentServerEnabled=true
