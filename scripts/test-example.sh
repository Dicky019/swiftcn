#!/bin/bash
#
#  test-example.sh
#  scripts/
#
#  Created by Dicky Darmawan on 07/02/26.
#
#  Runs Example app unit tests via xcodebuild.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

WORKSPACE="$PROJECT_ROOT/Example/Example.xcworkspace"
SCHEME="Example"
DESTINATION="${1:-platform=iOS Simulator,name=iPhone 16}"

if [ ! -d "$WORKSPACE" ]; then
    echo "Error: Workspace not found at $WORKSPACE"
    echo "Run 'cd Example && tuist generate' first."
    exit 1
fi

echo "Running Example tests..."
echo "Destination: $DESTINATION"
echo ""

xcodebuild test \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -quiet

echo ""
echo "Example tests passed."
