import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { RegistryServiceImpl } from "../../services/RegistryService.js";
import type { FileService } from "../../services/FileService.js";
import type { Registry } from "../../types/registry.schema.js";

const mockRegistry: Registry = {
  name: "swiftcn",
  version: "1.0.0",
  description: "test",
  license: "MIT",
  author: "test",
  repository: "https://github.com/test/test",
  config: {
    componentsPath: "Components",
    themePath: "Theme",
    sduiPath: "SDUI",
    platforms: ["iOS 17.0"],
    prefix: "CN",
  },
  theme: {
    core: ["Theme/Core/Theme.swift"],
    palettes: ["Theme/Palettes/ThemeDefaults.swift"],
    provider: ["Theme/Provider/ThemeProvider.swift"],
  },
  components: {
    button: {
      name: "CNButton",
      description: "A button",
      files: ["Components/CNButton.swift"],
      sdui_files: ["Components/CNButton+SDUI.swift"],
      variants: ["default", "destructive"],
      sizes: ["sm", "md", "lg"],
      sduiType: "button",
    },
    card: {
      name: "CNCard",
      description: "A card",
      files: ["Components/CNCard.swift"],
    },
  },
  sdui: {
    core: ["SDUI/Core/SDUINode.swift"],
    wrappers: ["SDUI/Wrappers/SDUIInputWrapper.swift"],
    transports: { json: "Built-in" },
  },
};

function createMockFileService(): FileService {
  return {
    copy: vi.fn(),
    exists: vi.fn(),
    readJson: vi.fn().mockResolvedValue(mockRegistry),
    writeJson: vi.fn(),
    ensureDir: vi.fn(),
    readFile: vi.fn(),
  };
}

describe("RegistryServiceImpl", () => {
  let service: RegistryServiceImpl;
  let mockFile: FileService;
  const originalFetch = globalThis.fetch;

  beforeEach(() => {
    mockFile = createMockFileService();
    service = new RegistryServiceImpl(mockFile);
  });

  afterEach(() => {
    globalThis.fetch = originalFetch;
  });

  describe("load", () => {
    it("fetches registry from remote", async () => {
      globalThis.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockRegistry),
      });

      const registry = await service.load();
      expect(registry.name).toBe("swiftcn");
      expect(globalThis.fetch).toHaveBeenCalledTimes(1);
      expect(mockFile.readJson).not.toHaveBeenCalled();
    });

    it("falls back to local when remote fails", async () => {
      globalThis.fetch = vi.fn().mockRejectedValue(new Error("Network error"));

      const registry = await service.load();
      expect(registry.name).toBe("swiftcn");
      expect(mockFile.readJson).toHaveBeenCalledTimes(1);
    });

    it("falls back to local on non-ok response", async () => {
      globalThis.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 404,
      });

      const registry = await service.load();
      expect(registry.name).toBe("swiftcn");
      expect(mockFile.readJson).toHaveBeenCalledTimes(1);
    });

    it("caches after first load", async () => {
      globalThis.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockRegistry),
      });

      await service.load();
      await service.load();
      expect(globalThis.fetch).toHaveBeenCalledTimes(1);
    });
  });

  describe("getComponent", () => {
    beforeEach(() => {
      globalThis.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockRegistry),
      });
    });

    it("returns component by name", async () => {
      const component = await service.getComponent("button");
      expect(component?.name).toBe("CNButton");
    });

    it("returns null for unknown component", async () => {
      const component = await service.getComponent("nonexistent");
      expect(component).toBeNull();
    });

    it("is case-insensitive", async () => {
      const component = await service.getComponent("BUTTON");
      expect(component?.name).toBe("CNButton");
    });
  });

  describe("listComponents", () => {
    beforeEach(() => {
      globalThis.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockRegistry),
      });
    });

    it("returns all components with ids", async () => {
      const components = await service.listComponents();
      expect(components).toHaveLength(2);
      expect(components[0].id).toBe("button");
      expect(components[1].id).toBe("card");
    });
  });

  describe("getThemeFiles", () => {
    beforeEach(() => {
      globalThis.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockRegistry),
      });
    });

    it("returns all theme file paths", async () => {
      const files = await service.getThemeFiles();
      expect(files).toContain("Theme/Core/Theme.swift");
      expect(files).toContain("Theme/Palettes/ThemeDefaults.swift");
      expect(files).toContain("Theme/Provider/ThemeProvider.swift");
    });
  });

  describe("getSduiFiles", () => {
    beforeEach(() => {
      globalThis.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve(mockRegistry),
      });
    });

    it("returns core and wrapper files", async () => {
      const files = await service.getSduiFiles();
      expect(files).toContain("SDUI/Core/SDUINode.swift");
      expect(files).toContain("SDUI/Wrappers/SDUIInputWrapper.swift");
    });
  });
});
