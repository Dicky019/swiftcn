#!/bin/bash
#
#  test-all.sh
#  scripts/
#
#  Created by Dicky Darmawan on 07/02/26.
#
#  Runs all tests: CLI (Vitest) + Example (xcodebuild).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== CLI Tests ==="
"$SCRIPT_DIR/test-cli.sh"

echo ""
echo "=== Example Tests ==="
"$SCRIPT_DIR/test-example.sh" "$@"
