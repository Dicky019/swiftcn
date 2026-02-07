#!/bin/bash
#
#  sync-source.sh
#  scripts/
#
#  Created by Dicky Darmawan on 07/02/26.
#
#  Syncs root Sources/ → Example/App/ to keep the Example app
#  in sync with the canonical template files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SRC="$PROJECT_ROOT/Sources/"
DEST="$PROJECT_ROOT/Example/App/"

if [ ! -d "$SRC" ]; then
    echo "Error: Sources directory not found at $SRC"
    exit 1
fi

DRY_RUN=""
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN="--dry-run"
fi

SUBDIRS=("Components" "Theme" "SDUI")

for dir in "${SUBDIRS[@]}"; do
    if [ -d "$SRC/$dir" ]; then
        rsync -a --checksum --delete --itemize-changes $DRY_RUN "$SRC/$dir/" "$DEST/$dir/"
    else
        echo "Warning: $SRC/$dir not found, skipping"
    fi
done

if [ -n "$DRY_RUN" ]; then
    echo ""
    echo "(dry run — no changes made)"
else
    echo "Synced Sources/{Components,Theme,SDUI} → Example/App/"
fi
