#!/bin/bash
#
#  test-e2e.sh
#  scripts/
#
#  Runs Maestro E2E test flows on iOS Simulator.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check Maestro installation
MAESTRO_BIN="${MAESTRO_BIN:-$(which maestro || echo "$HOME/.maestro/bin/maestro")}"
if [ ! -x "$MAESTRO_BIN" ]; then
  echo "Error: Maestro CLI not found. Install from https://docs.maestro.dev"
  exit 1
fi

echo "=== Maestro E2E Tests ==="
echo "Maestro: $($MAESTRO_BIN --version)"

# Check simulator
BOOTED_DEVICE=$(xcrun simctl list devices | grep -E '\(Booted\)' | head -n 1 || true)
if [ -z "$BOOTED_DEVICE" ]; then
  echo "No booted simulator found. Booting iPhone 17 Pro..."
  DEVICE_ID=$(xcrun simctl list devices available | grep -m 1 "iPhone 17 Pro" | grep -oE '\([A-F0-9-]+\)' | tr -d '()' || true)
  if [ -n "$DEVICE_ID" ]; then
    xcrun simctl boot "$DEVICE_ID" || true
  else
    xcrun simctl boot "iPhone 17 Pro" || true
  fi
fi

# Ensure app is installed
APP_PATH="$PROJECT_ROOT/Example/build/DerivedData/Build/Products/Debug-iphonesimulator/Example.app"
if [ -d "$APP_PATH" ]; then
  echo "Installing latest build: $APP_PATH"
  xcrun simctl install booted "$APP_PATH" || true
elif ! xcrun simctl listapps booted | grep -q "com.swiftcn.Example"; then
  echo "Error: Example.app not found at $APP_PATH and not installed on simulator."
  echo "Please build the app first: bash scripts/test-example.sh"
  exit 1
fi

FLOW_TARGET="${1:-$PROJECT_ROOT/.maestro}"

echo "Running Maestro flows from: $FLOW_TARGET"
"$MAESTRO_BIN" test "$FLOW_TARGET"
