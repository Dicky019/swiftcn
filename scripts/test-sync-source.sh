#!/bin/bash
#
#  test-sync-source.sh
#  scripts/
#
#  Created by Dicky Darmawan on 13/09/26.
#
#  Verifies synchronized navigation and Offline-First templates produce a clean dry run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

"$SCRIPT_DIR/sync-source.sh" >/dev/null

DRY_RUN_OUTPUT="$("$SCRIPT_DIR/sync-source.sh" --dry-run)"

if printf '%s\n' "$DRY_RUN_OUTPUT" | grep -Eq '^[^[:space:]]+ Router\.swift$'; then
    echo "Error: synchronized Router.swift was itemized by the dry run"
    printf '%s\n' "$DRY_RUN_OUTPUT"
    exit 1
fi

PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
for source in "$PROJECT_ROOT"/Sources/OfflineFirst/*.swift; do
    if [ ! -f "$source" ]; then
        continue
    fi
    filename="$(basename "$source")"
    if ! cmp -s "$source" "$PROJECT_ROOT/Example/App/OfflineFirst/$filename"; then
        echo "Error: OfflineFirst/$filename differs after synchronization"
        exit 1
    fi
    if printf '%s\n' "$DRY_RUN_OUTPUT" | grep -Eq "^[^[:space:]]+ ${filename//./\\.}$"; then
        echo "Error: synchronized OfflineFirst/$filename was itemized by the dry run"
        exit 1
    fi
done

echo "Sync source test passed."
