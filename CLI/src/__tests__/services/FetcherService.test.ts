import { describe, it, expect, vi, beforeEach } from "vitest";
import { FetcherServiceImpl } from "../../services/FetcherService.js";
import type { GitService } from "../../services/GitService.js";
import type { FileService, CopyResult } from "../../services/FileService.js";
import type { RegistryService } from "../../services/RegistryService.js";

function createMockGit(): GitService {
  return {
    clone: vi.fn(),
    cleanup: vi.fn(),
    createTempDir: vi.fn().mockReturnValue("/tmp/swiftcn-123"),
  };
}

function createMockFile(): FileService {
  return {
    copy: vi.fn().mockResolvedValue({ status: "added", path: "" } as CopyResult),
    exists: vi.fn(),
    readJson: vi.fn(),
    writeJson: vi.fn(),
    ensureDir: vi.fn(),
    readFile: vi.fn(),
  };
}

function createMockRegistry(): RegistryService {
  return {
    load: vi.fn(),
    getComponent: vi.fn(),
    listComponents: vi.fn(),
    getThemeFiles: vi
      .fn()
      .mockResolvedValue([
        "Theme/Core/Theme.swift",
        "Theme/Palettes/ThemeDefaults.swift",
      ]),
    getSduiFiles: vi
      .fn()
      .mockResolvedValue([
        "SDUI/Core/SDUINode.swift",
        "SDUI/Wrappers/SDUIInputWrapper.swift",
      ]),
  };
}

describe("FetcherServiceImpl", () => {
  let service: FetcherServiceImpl;
  let mockGit: GitService;
  let mockFile: FileService;
  let mockRegistry: RegistryService;

  beforeEach(() => {
    mockGit = createMockGit();
    mockFile = createMockFile();
    mockRegistry = createMockRegistry();
    service = new FetcherServiceImpl(mockGit, mockFile, mockRegistry);
  });

  describe("fetchComponents", () => {
    it("clones repo, copies files, and cleans up", async () => {
      const result = await service.fetchComponents(
        ["Components/CNButton.swift"],
        "/dest"
      );

      expect(mockGit.createTempDir).toHaveBeenCalledWith("swiftcn");
      expect(mockGit.clone).toHaveBeenCalled();
      expect(mockFile.copy).toHaveBeenCalledTimes(1);
      expect(mockGit.cleanup).toHaveBeenCalledWith("/tmp/swiftcn-123");
      expect(result.added).toHaveLength(1);
    });

    it("uses basename for component files (no strip prefix)", async () => {
      await service.fetchComponents(
        ["Components/CNButton.swift"],
        "/dest"
      );

      expect(mockFile.copy).toHaveBeenCalledWith(
        "/tmp/swiftcn-123/Sources/Components/CNButton.swift",
        "/dest/CNButton.swift",
        { force: undefined }
      );
    });

    it("passes force option through", async () => {
      await service.fetchComponents(
        ["Components/CNButton.swift"],
        "/dest",
        { force: true }
      );

      expect(mockFile.copy).toHaveBeenCalledWith(
        expect.any(String),
        expect.any(String),
        { force: true }
      );
    });

    it("tracks skipped files", async () => {
      vi.mocked(mockFile.copy).mockResolvedValue({
        status: "skipped",
        path: "/dest/CNButton.swift",
      });

      const result = await service.fetchComponents(
        ["Components/CNButton.swift"],
        "/dest"
      );

      expect(result.skipped).toHaveLength(1);
      expect(result.added).toHaveLength(0);
    });
  });

  describe("fetchTheme", () => {
    it("fetches theme files from registry and strips Theme/ prefix", async () => {
      await service.fetchTheme("/dest/theme");

      expect(mockRegistry.getThemeFiles).toHaveBeenCalled();
      expect(mockFile.copy).toHaveBeenCalledTimes(2);

      // Check Theme/ prefix is stripped
      expect(mockFile.copy).toHaveBeenCalledWith(
        "/tmp/swiftcn-123/Sources/Theme/Core/Theme.swift",
        "/dest/theme/Core/Theme.swift",
        { force: undefined }
      );
    });
  });

  describe("fetchSdui", () => {
    it("fetches SDUI files from registry and strips SDUI/ prefix", async () => {
      await service.fetchSdui("/dest/sdui");

      expect(mockRegistry.getSduiFiles).toHaveBeenCalled();
      expect(mockFile.copy).toHaveBeenCalledTimes(2);

      expect(mockFile.copy).toHaveBeenCalledWith(
        "/tmp/swiftcn-123/Sources/SDUI/Core/SDUINode.swift",
        "/dest/sdui/Core/SDUINode.swift",
        { force: undefined }
      );
    });
  });

  describe("cleanup on error", () => {
    it("cleans up temp directory even if clone fails", async () => {
      vi.mocked(mockGit.clone).mockRejectedValue(new Error("clone failed"));

      await expect(
        service.fetchComponents(["test.swift"], "/dest")
      ).rejects.toThrow("clone failed");

      expect(mockGit.cleanup).toHaveBeenCalledWith("/tmp/swiftcn-123");
    });
  });
});
