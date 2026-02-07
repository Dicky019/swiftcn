#!/bin/bash
#
#  test-cli.sh
#  scripts/
#
#  Created by Dicky Darmawan on 07/02/26.
#
#  Runs CLI unit tests via Vitest.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLI_DIR="$PROJECT_ROOT/CLI"

if [ ! -f "$CLI_DIR/package.json" ]; then
    echo "Error: CLI directory not found at $CLI_DIR"
    exit 1
fi

if [ ! -d "$CLI_DIR/node_modules" ]; then
    echo "Installing CLI dependencies..."
    npm --prefix "$CLI_DIR" install
    echo ""
fi

echo "Running CLI tests..."
echo ""

npm --prefix "$CLI_DIR" test
