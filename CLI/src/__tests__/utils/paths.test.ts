import { describe, it, expect } from "vitest";
import {
  sanitizePath,
  isPathTraversal,
  resolveSecurePath,
  isValidComponentName,
} from "../../utils/paths.js";
import { ErrorCode } from "../../utils/errors.js";

describe("sanitizePath", () => {
  it("normalizes a valid path", () => {
    expect(sanitizePath("foo/bar")).toBe("foo/bar");
  });

  it("trims whitespace", () => {
    expect(sanitizePath("  foo/bar  ")).toBe("foo/bar");
  });

  it("throws on empty string", () => {
    expect(() => sanitizePath("")).toThrow();
  });

  it("throws on path traversal", () => {
    expect(() => sanitizePath("../etc/passwd")).toThrow();
    expect(() => sanitizePath("foo/../../bar")).toThrow();
  });

  it("throws with PATH_TRAVERSAL error code", () => {
    try {
      sanitizePath("../test");
    } catch (e: any) {
      expect(e.code).toBe(ErrorCode.PATH_TRAVERSAL);
    }
  });
});

describe("isPathTraversal", () => {
  it("detects .. segments", () => {
    expect(isPathTraversal("../foo")).toBe(true);
    expect(isPathTraversal("foo/../bar")).toBe(true);
  });

  it("allows normal paths", () => {
    expect(isPathTraversal("foo/bar")).toBe(false);
    expect(isPathTraversal("Sources/Components")).toBe(false);
  });
});

describe("resolveSecurePath", () => {
  it("resolves a path within the base directory", () => {
    const result = resolveSecurePath("/project", "Sources/Components");
    expect(result).toBe("/project/Sources/Components");
  });

  it("throws on absolute relative path", () => {
    expect(() => resolveSecurePath("/project", "/etc/passwd")).toThrow();
  });

  it("throws on path that escapes base directory", () => {
    expect(() =>
      resolveSecurePath("/project", "../../etc/passwd")
    ).toThrow();
  });
});

describe("isValidComponentName", () => {
  it("accepts valid component names", () => {
    expect(isValidComponentName("button")).toBe(true);
    expect(isValidComponentName("my-component")).toBe(true);
    expect(isValidComponentName("Badge123")).toBe(true);
  });

  it("rejects empty names", () => {
    expect(isValidComponentName("")).toBe(false);
  });

  it("rejects names with special characters", () => {
    expect(isValidComponentName("foo bar")).toBe(false);
    expect(isValidComponentName("foo/bar")).toBe(false);
    expect(isValidComponentName("../test")).toBe(false);
  });

  it("rejects names exceeding max length", () => {
    expect(isValidComponentName("a".repeat(51))).toBe(false);
  });

  it("rejects names starting or ending with hyphen", () => {
    expect(isValidComponentName("-button")).toBe(false);
    expect(isValidComponentName("button-")).toBe(false);
  });
});
