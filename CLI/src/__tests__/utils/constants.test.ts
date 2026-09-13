import { describe, expect, it } from "vitest";
import { REGISTRY_URL, SOURCE_REF, VERSION } from "../../utils/constants.js";

describe("release source constants", () => {
  it("pins registry assets to the installed CLI version", () => {
    expect(SOURCE_REF).toBe(`v${VERSION}`);
    expect(REGISTRY_URL).toContain(`/${SOURCE_REF}/CLI/registry.json`);
  });
});
