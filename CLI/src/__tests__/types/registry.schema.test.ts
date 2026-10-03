import { readFile } from "node:fs/promises";
import { describe, expect, it } from "vitest";
import { registrySchema } from "../../types/registry.schema.js";

describe("registry.json", () => {
  it("registers exactly the three shared Offline-First templates", async () => {
    const raw = JSON.parse(await readFile(new URL("../../../registry.json", import.meta.url), "utf8"));
    expect(registrySchema.parse(raw).offlineFirst?.core).toEqual([
      "OfflineFirst/SyncTypes.swift", "OfflineFirst/RetryPolicy.swift", "OfflineFirst/SyncCoordinator.swift",
    ]);
  });

  it("rejects a substituted Offline-First source even when the count is three", async () => {
    const raw = JSON.parse(await readFile(new URL("../../../registry.json", import.meta.url), "utf8"));
    raw.offlineFirst = { core: ["OfflineFirst/SyncTypes.swift", "OfflineFirst/RetryPolicy.swift", "Components/CNButton.swift"] };
    expect(() => registrySchema.parse(raw)).toThrow();
  });
  it("registers the navigation template", async () => {
    const raw = await readFile(
      new URL("../../../registry.json", import.meta.url),
      "utf8"
    );
    const registry = registrySchema.parse(JSON.parse(raw));

    expect(registry.components.navigation).toEqual({
      name: "Router",
      description: "A typed navigation router for SwiftUI",
      files: ["Navigation/Router.swift"],
    });
  });
});
