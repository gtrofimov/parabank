#!/usr/bin/env bash
set -euo pipefail

# Compatibility wrapper. New skills use workflow-config/scripts/resolve-build-id.sh.
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
exec "$script_dir/../../workflow-config/scripts/resolve-build-id.sh"