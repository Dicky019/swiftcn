import { describe, it, expect } from "vitest";
import { SwiftCNError, ErrorCode } from "../../utils/errors.js";

describe("SwiftCNError", () => {
  it("creates error with message and code", () => {
    const error = new SwiftCNError("test error", ErrorCode.CONFIG_NOT_FOUND);
    expect(error.message).toBe("test error");
    expect(error.code).toBe(ErrorCode.CONFIG_NOT_FOUND);
    expect(error.name).toBe("SwiftCNError");
  });

  it("is an instance of Error", () => {
    const error = new SwiftCNError("test", ErrorCode.INVALID_INPUT);
    expect(error).toBeInstanceOf(Error);
    expect(error).toBeInstanceOf(SwiftCNError);
  });

  it("has a stack trace", () => {
    const error = new SwiftCNError("test", ErrorCode.GIT_CLONE_FAILED);
    expect(error.stack).toBeDefined();
  });
});

describe("ErrorCode", () => {
  it("has all expected codes", () => {
    expect(ErrorCode.CONFIG_NOT_FOUND).toBe("CONFIG_NOT_FOUND");
    expect(ErrorCode.COMPONENT_NOT_FOUND).toBe("COMPONENT_NOT_FOUND");
    expect(ErrorCode.PATH_TRAVERSAL).toBe("PATH_TRAVERSAL");
    expect(ErrorCode.INVALID_INPUT).toBe("INVALID_INPUT");
    expect(ErrorCode.GIT_CLONE_FAILED).toBe("GIT_CLONE_FAILED");
    expect(ErrorCode.FILE_COPY_FAILED).toBe("FILE_COPY_FAILED");
    expect(ErrorCode.REGISTRY_LOAD_FAILED).toBe("REGISTRY_LOAD_FAILED");
  });
});
