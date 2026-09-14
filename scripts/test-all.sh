#!/bin/bash
#
#  test-all.sh
#  scripts/
#
#  Runs all tests: CLI (Vitest) + Example (xcodebuild) + optional E2E (Maestro).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RUN_E2E=false
PASSTHROUGH_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --e2e)
      RUN_E2E=true
      ;;
    *)
      PASSTHROUGH_ARGS+=("$arg")
      ;;
  esac
done

echo "=== CLI Tests ==="
"$SCRIPT_DIR/test-cli.sh"

echo ""
echo "=== Sync Source Test ==="
"$SCRIPT_DIR/test-sync-source.sh"

echo ""
echo "=== Example Tests ==="
"$SCRIPT_DIR/test-example.sh" "${PASSTHROUGH_ARGS[@]:-}"

if [ "$RUN_E2E" = true ]; then
  echo ""
  echo "=== Maestro E2E Tests ==="
  "$SCRIPT_DIR/test-e2e.sh"
fi
