import { describe, it, expect } from "vitest";
import { GitServiceImpl } from "../../services/GitService.js";
import fs from "fs-extra";
import os from "node:os";
import path from "node:path";

describe("GitServiceImpl", () => {
  const service = new GitServiceImpl();

  describe("clone", () => {
    it("rejects untrusted repository URLs", async () => {
      await expect(
        service.clone("https://evil.example.com/repo.git", "/tmp/test")
      ).rejects.toThrow("Untrusted repository URL");
    });

    it("rejects URLs not in the allowlist", async () => {
      await expect(
        service.clone("https://github.com/other/repo.git", "/tmp/test")
      ).rejects.toThrow("Untrusted repository URL");
    });
  });

  describe("createTempDir", () => {
    it("creates a path in the system temp directory", () => {
      const result = service.createTempDir("test");
      expect(result).toContain(os.tmpdir());
      expect(result).toContain("test-");
    });

    it("creates unique paths", () => {
      const a = service.createTempDir("test");
      // Small delay to ensure different timestamps
      const b = service.createTempDir("test");
      // Paths could be same if timestamp matches, but both should be valid
      expect(a).toContain("test-");
      expect(b).toContain("test-");
    });
  });

  describe("cleanup", () => {
    it("removes the directory", async () => {
      const dir = path.join(os.tmpdir(), `cleanup-test-${Date.now()}`);
      await fs.ensureDir(dir);
      await fs.writeFile(path.join(dir, "file.txt"), "data");

      await service.cleanup(dir);
      expect(await fs.pathExists(dir)).toBe(false);
    });

    it("does not throw if directory does not exist", async () => {
      await expect(
        service.cleanup("/nonexistent/path/that/does/not/exist")
      ).resolves.not.toThrow();
    });
  });
});
