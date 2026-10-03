#!/bin/bash
# Compile and run every architecture recipe on an iOS simulator.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURE="$PROJECT_ROOT/Fixtures/ArchitecturePresets"
DESTINATION="${1:-platform=iOS Simulator,name=iPhone 17 Pro}"

# Inner layers have no presentation, transport, persistence, or vendor dependencies.
if rg -n '\bimport[[:space:]]+(SwiftUI|ComposableArchitecture|SwiftData|CoreData|FoundationNetworking|Router)\b|\b(URLSession|Router)\b' \
  "$FIXTURE/Sources/PresetDomain" "$FIXTURE/Sources/PresetApplication"; then
  echo "Error: forbidden dependency in Domain/Application." >&2
  exit 1
else
  status=$?
  if [ "$status" -ne 1 ]; then exit "$status"; fi
fi
if rg -n '\bRouter\b|\bimport[[:space:]]+PresetNavigation\b' "$FIXTURE/Sources/TCAPreset"; then
  echo "Error: TCA must own navigation through reducer state." >&2
  exit 1
else
  status=$?
  if [ "$status" -ne 1 ]; then exit "$status"; fi
fi

# Generate only the repository test harness; init never generates a user's project.
(cd "$FIXTURE" && tuist generate --no-open)
xcodebuild test \
  -workspace "$FIXTURE/ArchitecturePresets.xcworkspace" \
  -scheme ArchitecturePresets \
  -destination "$DESTINATION" \
  -derivedDataPath "$FIXTURE/.build/DerivedData" \
  -clonedSourcePackagesDirPath "$FIXTURE/.build/SourcePackages" \
  -parallel-testing-enabled NO \
  -skipMacroValidation \
  -quiet

echo "Architecture preset tests and dependency gates passed."
