import { describe, it, expect } from "vitest";
import {
  InitOptionsSchema,
  AddOptionsSchema,
  ListOptionsSchema,
} from "../../types/options.schema.js";

describe("InitOptionsSchema", () => {
  it("applies defaults when no options provided", () => {
    const result = InitOptionsSchema.parse({});
    expect(result.path).toBe("Sources/Components");
    expect(result.themePath).toBe("Sources/Theme");
    expect(result.sduiPath).toBe("Sources/SDUI");
  });

  it("accepts custom paths", () => {
    const result = InitOptionsSchema.parse({
      path: "App/Components",
      themePath: "App/Theme",
      sduiPath: "App/SDUI",
    });
    expect(result.path).toBe("App/Components");
    expect(result.themePath).toBe("App/Theme");
    expect(result.sduiPath).toBe("App/SDUI");
  });

  it("accepts sdui flag", () => {
    const result = InitOptionsSchema.parse({ sdui: true });
    expect(result.sdui).toBe(true);
  });

  it("does not have a theme flag", () => {
    const result = InitOptionsSchema.parse({ theme: true });
    // theme flag is stripped — theme is always included
    expect("theme" in result).toBe(false);
  });

  it("accepts yes flag", () => {
    const result = InitOptionsSchema.parse({ yes: true });
    expect(result.yes).toBe(true);
  });
});

describe("AddOptionsSchema", () => {
  it("accepts force flag", () => {
    const result = AddOptionsSchema.parse({ force: true });
    expect(result.force).toBe(true);
  });

  it("accepts sdui false for --no-sdui", () => {
    const result = AddOptionsSchema.parse({ sdui: false });
    expect(result.sdui).toBe(false);
  });

  it("defaults to undefined when no flags", () => {
    const result = AddOptionsSchema.parse({});
    expect(result.force).toBeUndefined();
    expect(result.sdui).toBeUndefined();
  });

  it("does not have a theme flag", () => {
    const result = AddOptionsSchema.parse({ theme: true });
    expect("theme" in result).toBe(false);
  });
});

describe("ListOptionsSchema", () => {
  it("accepts verbose flag", () => {
    const result = ListOptionsSchema.parse({ verbose: true });
    expect(result.verbose).toBe(true);
  });

  it("defaults to undefined", () => {
    const result = ListOptionsSchema.parse({});
    expect(result.verbose).toBeUndefined();
  });
});
