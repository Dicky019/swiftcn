import { readFile } from "node:fs/promises";
import { describe, expect, it } from "vitest";
import { registrySchema } from "../../types/registry.schema.js";

describe("registry.json", () => {
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
