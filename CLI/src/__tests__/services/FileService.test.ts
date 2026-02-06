import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { FileServiceImpl } from "../../services/FileService.js";
import { z } from "zod";
import fs from "fs-extra";
import path from "node:path";
import os from "node:os";

describe("FileServiceImpl", () => {
  let service: FileServiceImpl;
  let tempDir: string;

  beforeEach(async () => {
    service = new FileServiceImpl();
    tempDir = path.join(os.tmpdir(), `fileservice-test-${Date.now()}`);
    await fs.ensureDir(tempDir);
  });

  afterEach(async () => {
    await fs.remove(tempDir);
  });

  describe("copy", () => {
    it("copies a file to destination", async () => {
      const source = path.join(tempDir, "source.txt");
      const dest = path.join(tempDir, "dest.txt");
      await fs.writeFile(source, "hello");

      const result = await service.copy(source, dest);
      expect(result.status).toBe("added");
      expect(await fs.readFile(dest, "utf-8")).toBe("hello");
    });

    it("skips if destination exists and force is false", async () => {
      const source = path.join(tempDir, "source.txt");
      const dest = path.join(tempDir, "dest.txt");
      await fs.writeFile(source, "hello");
      await fs.writeFile(dest, "existing");

      const result = await service.copy(source, dest);
      expect(result.status).toBe("skipped");
      expect(await fs.readFile(dest, "utf-8")).toBe("existing");
    });

    it("overwrites if force is true", async () => {
      const source = path.join(tempDir, "source.txt");
      const dest = path.join(tempDir, "dest.txt");
      await fs.writeFile(source, "new content");
      await fs.writeFile(dest, "old content");

      const result = await service.copy(source, dest, { force: true });
      expect(result.status).toBe("added");
      expect(await fs.readFile(dest, "utf-8")).toBe("new content");
    });

    it("returns error if source does not exist", async () => {
      const result = await service.copy(
        path.join(tempDir, "nonexistent"),
        path.join(tempDir, "dest.txt")
      );
      expect(result.status).toBe("error");
    });

    it("creates destination directory if needed", async () => {
      const source = path.join(tempDir, "source.txt");
      const dest = path.join(tempDir, "sub/dir/dest.txt");
      await fs.writeFile(source, "hello");

      const result = await service.copy(source, dest);
      expect(result.status).toBe("added");
      expect(await fs.pathExists(dest)).toBe(true);
    });
  });

  describe("exists", () => {
    it("returns true for existing file", async () => {
      const file = path.join(tempDir, "exists.txt");
      await fs.writeFile(file, "data");

      expect(await service.exists(file)).toBe(true);
    });

    it("returns false for non-existing file", async () => {
      expect(await service.exists(path.join(tempDir, "nope"))).toBe(false);
    });
  });

  describe("readJson", () => {
    it("reads and validates JSON with a Zod schema", async () => {
      const schema = z.object({ name: z.string(), count: z.number() });
      const file = path.join(tempDir, "data.json");
      await fs.writeFile(file, JSON.stringify({ name: "test", count: 42 }));

      const result = await service.readJson(file, schema);
      expect(result).toEqual({ name: "test", count: 42 });
    });

    it("throws on invalid JSON structure", async () => {
      const schema = z.object({ name: z.string() });
      const file = path.join(tempDir, "bad.json");
      await fs.writeFile(file, JSON.stringify({ wrong: true }));

      await expect(service.readJson(file, schema)).rejects.toThrow();
    });
  });

  describe("writeJson", () => {
    it("writes JSON with pretty formatting", async () => {
      const file = path.join(tempDir, "out.json");
      await service.writeJson(file, { key: "value" });

      const content = await fs.readFile(file, "utf-8");
      expect(content).toContain('"key": "value"');
      expect(content.endsWith("\n")).toBe(true);
    });
  });

  describe("ensureDir", () => {
    it("creates directory if it does not exist", async () => {
      const dir = path.join(tempDir, "new/nested/dir");
      await service.ensureDir(dir);
      expect(await fs.pathExists(dir)).toBe(true);
    });
  });

  describe("readFile", () => {
    it("reads file content as string", async () => {
      const file = path.join(tempDir, "read.txt");
      await fs.writeFile(file, "contents here");

      expect(await service.readFile(file)).toBe("contents here");
    });
  });
});
