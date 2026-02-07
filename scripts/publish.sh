#!/bin/bash
#
#  publish.sh
#  scripts/
#
#  Created by Dicky Darmawan on 08/02/26.
#
#  Full publish workflow: update version, test, commit, tag, release, npm publish.
#  Usage: ./scripts/publish.sh <version>
#  Example: ./scripts/publish.sh 1.0.2

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI_DIR="$PROJECT_ROOT/CLI"

VERSION="${1:-}"

if [ -z "$VERSION" ]; then
    echo "Usage: ./scripts/publish.sh <version>"
    echo "Example: ./scripts/publish.sh 1.0.2"
    exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Invalid version format \"$VERSION\". Use semver (e.g. 1.0.2)"
    exit 1
fi

echo "Publishing swiftcn v$VERSION"
echo "================================"

# 1. Update versions (package.json, registry.json) + sync + build
echo ""
echo "[1/6] Updating version & building..."
cd "$CLI_DIR" && node scripts/update.js "$VERSION"

# 2. Run CLI tests
echo ""
echo "[2/6] Running CLI tests..."
cd "$CLI_DIR" && npm test

# 3. Amend version bump into previous commit
echo ""
echo "[3/6] Amending commit..."
cd "$PROJECT_ROOT"
git add -A
git commit --amend --no-edit

# 4. Tag
echo ""
echo "[4/6] Creating tag v$VERSION..."
git tag -a "v$VERSION" -m "v$VERSION"

# 5. Push + tag
echo ""
echo "[5/6] Pushing to GitHub..."
git push origin main --tags --force-with-lease

# 6. GitHub Release
echo ""
echo "[6/6] Creating GitHub release..."
gh release create "v$VERSION" \
    --title "v$VERSION" \
    --generate-notes

echo ""
echo "================================"
echo "v$VERSION published!"
echo ""
echo "To publish to npm:"
echo "  cd CLI && npm publish"
