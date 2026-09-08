#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../workflow-config/scripts/load-orchestration-config.sh
source "$script_dir/../../workflow-config/scripts/load-orchestration-config.sh"

# Builds target/jtest/monitor/monitor.zip from compiled classes. Licensing is
# read from $JTEST_HOME/jtestcli.properties; project settings are command-line
# properties so CI does not depend on a repo-local Jtest settings file.
mvn package jtest:monitor -DskipTests \
    -Djtest.agentServerEnabled=true \
    -Dreport.coverage.static.images="$DTP_SOATEST_COVERAGE_IMAGES"
