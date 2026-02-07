#!/usr/bin/env node

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";

const __dirname = dirname(fileURLToPath(import.meta.url));
const cliRoot = join(__dirname, "..");
const projectRoot = join(cliRoot, "..");

const version = process.argv[2];
if (!version) {
  console.error("Usage: npm run update -- <version>");
  console.error("Example: npm run update -- 1.0.2");
  process.exit(1);
}

if (!/^\d+\.\d+\.\d+$/.test(version)) {
  console.error(`Invalid version format: "${version}". Use semver (e.g. 1.0.2)`);
  process.exit(1);
}

// 1. Update package.json
const pkgPath = join(cliRoot, "package.json");
const pkg = JSON.parse(readFileSync(pkgPath, "utf-8"));
const oldVersion = pkg.version;
pkg.version = version;
writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + "\n");
console.log(`package.json  ${oldVersion} → ${version}`);

// 2. Update registry.json
const registryPath = join(cliRoot, "registry.json");
const registry = JSON.parse(readFileSync(registryPath, "utf-8"));
registry.version = version;
writeFileSync(registryPath, JSON.stringify(registry, null, 2) + "\n");
console.log(`registry.json ${oldVersion} → ${version}`);

// 3. Sync Sources/ → Example/App/
const syncScript = join(projectRoot, "scripts", "sync-source.sh");
if (existsSync(syncScript)) {
  console.log("\nSyncing Sources/ → Example/App/...");
  execFileSync("bash", [syncScript], { stdio: "inherit" });
} else {
  console.log("\nSkipped sync (scripts/sync-source.sh not found)");
}

// 4. Build
console.log("\nBuilding CLI...");
execFileSync("npx", ["tsc"], { cwd: cliRoot, stdio: "inherit" });

console.log(`\nDone! v${version} ready.`);
