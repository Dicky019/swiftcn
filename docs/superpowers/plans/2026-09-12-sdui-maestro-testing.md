# SDUI Maestro E2E Testing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create an automated, robust end-to-end (E2E) testing suite for the Server-Driven UI (SDUI) Playground using Maestro CLI on iOS.

**Architecture:** Define declarative YAML test flows under `.maestro/` targeting `com.swiftcn.Example`. Create reusable subflows for app navigation, comprehensive interaction tests for all 3 power showcase templates (E-Commerce Checkout, SaaS Dashboard, Smart Settings), modal sheet validations (Template Picker and JSON Editor), and live action toast verifications. Provide a turnkey `scripts/test-e2e.sh` runner.

**Tech Stack:** Maestro CLI 2.7.0+, YAML, iOS Simulator (iPhone 17 Pro), Bash, swiftcn Example App (`com.swiftcn.Example`).

**Spec:** `docs/superpowers/specs/2026-09-11-foundation-hardening-design.md`

## Global Constraints

- Target app identifier: `com.swiftcn.Example`.
- iOS simulator: `iPhone 17 Pro` (or any booted iOS 17+ simulator).
- Maestro flows must use clean accessibility identifiers, visible text assertions, and resilient timeouts.
- Flows must test real-world SDUI capabilities: switches, inputs, sliders, cards, buttons, badges, template selection, and live action toast feedback.
- Every flow must be runnable standalone via `maestro test <flow.yaml>` or together via `scripts/test-e2e.sh`.
- Canonical files committed with verified GPG signature (`66B9DEA9A6984AD9`).

## File Map

- `.maestro/subflows/launch-sdui.yaml`: Reusable subflow to launch app and ensure SDUI Playground is visible.
- `.maestro/sdui-ecommerce-checkout.yaml`: E2E flow testing the default E-Commerce Checkout template (switches, inputs, buttons, toasts).
- `.maestro/sdui-template-picker.yaml`: E2E flow testing the Templates modal picker, switching templates to SaaS Dashboard and Smart Settings.
- `.maestro/sdui-json-editor.yaml`: E2E flow testing the right navigation bar JSON Editor sheet, format button, and dismissal.
- `.maestro/sdui-action-toast.yaml`: E2E flow testing action toast display and auto-dismissal.
- `scripts/test-e2e.sh`: Turnkey script to check simulator, verify app build, and run Maestro flows.
- `scripts/test-all.sh`: Update to optionally run E2E tests when `--e2e` is passed.
- `README.md`, `Example/README.md`: Documentation on how to run Maestro E2E tests.

---

### Task 1: Maestro Scaffolding & Launch Subflow

**Files:**
- Create: `.maestro/subflows/launch-sdui.yaml`
- Create: `scripts/test-e2e.sh`

**Interfaces:**
- Produces: `.maestro/subflows/launch-sdui.yaml` consumed by all SDUI test flows.
- Produces: `scripts/test-e2e.sh` executable by developers and CI.

- [ ] **Step 1: Create the launch-sdui reusable subflow**

Create `.maestro/subflows/launch-sdui.yaml`:
```yaml
appId: com.swiftcn.Example
---
- launchApp:
    clearState: false
    arguments:
      -sdui: ""
- runFlow:
    when:
      notVisible: "SDUI Playground"
    commands:
      - tapOn:
          text: "SDUI"
- assertVisible: "SDUI Playground"
```

- [ ] **Step 2: Create `scripts/test-e2e.sh` executable runner**

Create `scripts/test-e2e.sh`:
```bash
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
  xcrun simctl boot "iPhone 17 Pro" || true
fi

# Ensure app is installed
APP_PATH="$PROJECT_ROOT/Example/build/DerivedData/Build/Products/Debug-iphonesimulator/Example.app"
if [ -d "$APP_PATH" ]; then
  echo "Installing latest build: $APP_PATH"
  xcrun simctl install booted "$APP_PATH" || true
fi

FLOW_TARGET="${1:-$PROJECT_ROOT/.maestro}"

echo "Running Maestro flows from: $FLOW_TARGET"
"$MAESTRO_BIN" test "$FLOW_TARGET"
```

Make it executable:
```bash
chmod +x scripts/test-e2e.sh
```

- [ ] **Step 3: Verify the launch subflow with Maestro**

Run:
```bash
/Users/diki/.maestro/bin/maestro test .maestro/subflows/launch-sdui.yaml
```
Expected: PASS with "SDUI Playground" asserted visible.

- [ ] **Step 4: Commit**

```bash
git add .maestro/subflows/launch-sdui.yaml scripts/test-e2e.sh
git commit -S -m "test(sdui): add maestro scaffolding and launch subflow"
```

---

### Task 2: E-Commerce Checkout SDUI Flow

**Files:**
- Create: `.maestro/sdui-ecommerce-checkout.yaml`

**Interfaces:**
- Consumes: `.maestro/subflows/launch-sdui.yaml`
- Tests: `ecommerce-checkout` template interactive controls (switches, inputs, buttons, sliders).

- [ ] **Step 1: Write `sdui-ecommerce-checkout.yaml`**

Create `.maestro/sdui-ecommerce-checkout.yaml`:
```yaml
appId: com.swiftcn.Example
---
- runFlow: subflows/launch-sdui.yaml

# Verify E-Commerce template elements
- assertVisible: "E-Commerce Checkout"
- assertVisible: "Shopping Cart"
- assertVisible: "2 Items"
- assertVisible: "Studio Pro Headphones"
- assertVisible: "-20% OFF"
- assertVisible: "Delivery & Options"
- assertVisible: "Estimated Total"
- assertVisible: "\\$255.00"

# Test full-row switch toggle: Express Priority Shipping
- tapOn: "Express Priority Shipping"
- assertVisible: "Action: express_shipping.*"

# Test full-row switch toggle: Eco-Friendly Gift Wrapping
- tapOn: "Eco-Friendly Gift Wrapping"
- assertVisible: "Action: gift_wrapping.*"

# Test Promo Code Input Field
- tapOn: "e.g. SWIFTCN20"
- inputText: "SWIFT2026"
- hideKeyboard
- assertVisible: "Action: promo_code.*"

# Test Button action
- tapOn: "Wishlist"
- assertVisible: "Action: add_wishlist"
```

- [ ] **Step 2: Run Maestro flow to verify**

Run:
```bash
/Users/diki/.maestro/bin/maestro test .maestro/sdui-ecommerce-checkout.yaml
```
Expected: PASS with all assertions and interactions succeeding.

- [ ] **Step 3: Commit**

```bash
git add .maestro/sdui-ecommerce-checkout.yaml
git commit -S -m "test(sdui): add maestro e2e test for ecommerce checkout template"
```

---

### Task 3: Template Picker & Multi-Showcase Flow

**Files:**
- Create: `.maestro/sdui-template-picker.yaml`

**Interfaces:**
- Consumes: `.maestro/subflows/launch-sdui.yaml`
- Tests: Left navigation Templates picker button, modal sheet rendering, and template switching to SaaS Dashboard and Smart Settings Hub.

- [ ] **Step 1: Write `sdui-template-picker.yaml`**

Create `.maestro/sdui-template-picker.yaml`:
```yaml
appId: com.swiftcn.Example
---
- runFlow: subflows/launch-sdui.yaml

# Open Templates Picker from top-left nav
- tapOn:
    point: "8%,7%"
- assertVisible: "Featured Showcases"
- assertVisible: "SaaS Analytics & Cloud Dashboard"
- assertVisible: "Smart Account & Security Hub"

# Switch to SaaS Analytics & Cloud Dashboard
- tapOn: "SaaS Analytics & Cloud Dashboard"
- assertVisible: "SaaS Analytics & Cloud Dashboard"
- assertVisible: "Cloud Cluster Alpha"
- assertVisible: "OPERATIONAL"
- assertVisible: "US-East-1"
- assertVisible: "Auto-Scale Replicas"
- assertVisible: "Monthly Traffic Capacity"

# Test SaaS interaction
- tapOn: "Auto-Scale Replicas"
- assertVisible: "Action: auto_scale.*"

- tapOn: "Deploy Hotfix"
- assertVisible: "Action: deploy_hotfix"

# Switch to Smart Account & Security Hub
- tapOn:
    point: "8%,7%"
- assertVisible: "Featured Showcases"
- tapOn: "Smart Account & Security Hub"
- assertVisible: "Smart Account & Security Hub"
- assertVisible: "Security & Access Hub"
- assertVisible: "EXCELLENT"
- assertVisible: "Enforce Hardware 2FA"
- assertVisible: "Danger Zone"
- assertVisible: "Revoke All Keys"
- assertVisible: "Lock Workspace"

# Test Smart Settings interaction
- tapOn: "Enforce Hardware 2FA"
- assertVisible: "Action: hardware_2fa.*"

- tapOn: "Lock Workspace"
- assertVisible: "Action: lock_workspace"
```

- [ ] **Step 2: Run Maestro flow to verify**

Run:
```bash
/Users/diki/.maestro/bin/maestro test .maestro/sdui-template-picker.yaml
```
Expected: PASS with all template transitions and interactions verified.

- [ ] **Step 3: Commit**

```bash
git add .maestro/sdui-template-picker.yaml
git commit -S -m "test(sdui): add maestro e2e test for template picker and showcases"
```

---

### Task 4: JSON Editor Sheet Flow

**Files:**
- Create: `.maestro/sdui-json-editor.yaml`

**Interfaces:**
- Consumes: `.maestro/subflows/launch-sdui.yaml`
- Tests: Right navigation bar JSON Editor sheet (`topBarTrailing`), pretty-print formatting, and sheet dismissal.

- [ ] **Step 1: Write `sdui-json-editor.yaml`**

Create `.maestro/sdui-json-editor.yaml`:
```yaml
appId: com.swiftcn.Example
---
- runFlow: subflows/launch-sdui.yaml

# Open JSON Editor from top-right nav
- tapOn:
    point: "92%,7%"
- assertVisible: "JSON Input"
- assertVisible: "Format"
- assertVisible: "Done"

# Tap Format button
- tapOn: "Format"

# Dismiss sheet via Done
- tapOn: "Done"
- assertNotVisible: "JSON Input"
- assertVisible: "SDUI Playground"
```

- [ ] **Step 2: Run Maestro flow to verify**

Run:
```bash
/Users/diki/.maestro/bin/maestro test .maestro/sdui-json-editor.yaml
```
Expected: PASS with modal sheet verified and cleanly dismissed.

- [ ] **Step 3: Commit**

```bash
git add .maestro/sdui-json-editor.yaml
git commit -S -m "test(sdui): add maestro e2e test for json editor sheet"
```

---

### Task 5: Scripts, CI & Documentation Integration

**Files:**
- Modify: `scripts/test-all.sh:1-20`
- Modify: `README.md`
- Modify: `Example/README.md`

**Interfaces:**
- Produces: Seamless `--e2e` flag on `scripts/test-all.sh`.
- Produces: Clear documentation for developers to run local and CI Maestro tests.

- [ ] **Step 1: Update `scripts/test-all.sh` to support `--e2e`**

Update `scripts/test-all.sh`:
```bash
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
echo "=== Example Tests ==="
"$SCRIPT_DIR/test-example.sh" "${PASSTHROUGH_ARGS[@]:-}"

if [ "$RUN_E2E" = true ]; then
  echo ""
  echo "=== Maestro E2E Tests ==="
  "$SCRIPT_DIR/test-e2e.sh"
fi
```

- [ ] **Step 2: Update `Example/README.md` and root `README.md` with Maestro instructions**

Add Maestro section explaining how to run E2E tests:
```markdown
### E2E Testing with Maestro

The Example app includes automated E2E tests powered by [Maestro](https://docs.maestro.dev):

```bash
# Run all E2E flows
./scripts/test-e2e.sh

# Or run a specific flow
maestro test .maestro/sdui-ecommerce-checkout.yaml
maestro test .maestro/sdui-template-picker.yaml
maestro test .maestro/sdui-json-editor.yaml
```
```

- [ ] **Step 3: Run complete verification suite**

Run:
```bash
bash scripts/test-all.sh --e2e
```
Expected:
- CLI Tests: 108 passed
- Example Tests: 100% passed
- Maestro E2E: All flows passed

- [ ] **Step 4: Commit and push**

```bash
git add scripts/test-all.sh README.md Example/README.md
git commit -S -m "docs(sdui): document maestro e2e test suite and runner"
git push origin fix/sdui
```

---

## Verification Plan

### Automated Tests
1. **Maestro Flow Execution**:
   - `scripts/test-e2e.sh` passes 100% on iOS Simulator.
   - Individual flow executions:
     - `maestro test .maestro/sdui-ecommerce-checkout.yaml`
     - `maestro test .maestro/sdui-template-picker.yaml`
     - `maestro test .maestro/sdui-json-editor.yaml`
2. **Regression Check**:
   - `bash scripts/test-example.sh` (Xcode unit tests pass).
   - `npm --prefix CLI test` (Vitest passes).
   - `npm --prefix CLI run build` (Typecheck passes).

### Manual Verification
- Visual confirmation during Maestro playback on iOS Simulator that switches toggle, inputs type, buttons click, and templates switch smoothly.
