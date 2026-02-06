import { describe, it, expect, vi, beforeEach } from "vitest";
import { ConfigServiceImpl } from "../../services/ConfigService.js";
import type { FileService } from "../../services/FileService.js";
import type { ProjectConfig } from "../../types/config.schema.js";

function createMockFileService(overrides: Partial<FileService> = {}): FileService {
  return {
    copy: vi.fn(),
    exists: vi.fn().mockResolvedValue(false),
    readJson: vi.fn(),
    writeJson: vi.fn(),
    ensureDir: vi.fn(),
    readFile: vi.fn(),
    ...overrides,
  };
}

describe("ConfigServiceImpl", () => {
  let service: ConfigServiceImpl;
  let mockFile: FileService;

  const sampleConfig: ProjectConfig = {
    componentsPath: "Sources/Components",
    themePath: "Sources/Theme",
    prefix: "CN",
  };

  describe("load", () => {
    it("returns null when config does not exist", async () => {
      mockFile = createMockFileService({
        exists: vi.fn().mockResolvedValue(false),
      });
      service = new ConfigServiceImpl(mockFile);

      const result = await service.load("/project");
      expect(result).toBeNull();
    });

    it("reads and parses config when it exists", async () => {
      mockFile = createMockFileService({
        exists: vi.fn().mockResolvedValue(true),
        readJson: vi.fn().mockResolvedValue(sampleConfig),
      });
      service = new ConfigServiceImpl(mockFile);

      const result = await service.load("/project");
      expect(result).toEqual(sampleConfig);
      expect(mockFile.readJson).toHaveBeenCalledWith(
        "/project/swiftcn.json",
        expect.anything()
      );
    });
  });

  describe("write", () => {
    it("writes config to file", async () => {
      mockFile = createMockFileService();
      service = new ConfigServiceImpl(mockFile);

      await service.write(sampleConfig, "/project");
      expect(mockFile.writeJson).toHaveBeenCalledWith(
        "/project/swiftcn.json",
        sampleConfig
      );
    });
  });

  describe("exists", () => {
    it("checks if config file exists", async () => {
      mockFile = createMockFileService({
        exists: vi.fn().mockResolvedValue(true),
      });
      service = new ConfigServiceImpl(mockFile);

      expect(await service.exists("/project")).toBe(true);
      expect(mockFile.exists).toHaveBeenCalledWith("/project/swiftcn.json");
    });
  });
});
