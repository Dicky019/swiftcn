#!/bin/bash
#
#  test-sync-source.sh
#  scripts/
#
#  Created by Dicky Darmawan on 13/09/26.
#
#  Verifies a synchronized Router template produces a clean dry run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$SCRIPT_DIR/sync-source.sh" >/dev/null

DRY_RUN_OUTPUT="$("$SCRIPT_DIR/sync-source.sh" --dry-run)"

if printf '%s\n' "$DRY_RUN_OUTPUT" | grep -Eq '^[^[:space:]]+ Router\.swift$'; then
    echo "Error: synchronized Router.swift was itemized by the dry run"
    printf '%s\n' "$DRY_RUN_OUTPUT"
    exit 1
fi

echo "Sync source test passed."
