import { describe, it, expect, vi, beforeEach } from "vitest";
import { createAddCommand } from "../../commands/add.js";
import type { Container } from "../../container.js";
import type { FetchResult } from "../../services/FetcherService.js";
import {
  createMockContainer,
  createProgram,
  sampleConfig,
  sampleConfigWithSdui,
  sampleButton,
  sampleComponents,
} from "./helpers.js";

const addedResult: FetchResult = {
  added: ["/project/Components/CNButton.swift"],
  skipped: [],
};

const addedWithSduiResult: FetchResult = {
  added: [
    "/project/Components/CNButton.swift",
    "/project/Components/CNButton+SDUI.swift",
  ],
  skipped: [],
};

async function runAdd(
  args: string[],
  containerOverrides: Partial<Container> = {}
) {
  const container = createMockContainer(containerOverrides);
  const cmd = createAddCommand(container);

  const mockExit = vi
    .spyOn(process, "exit")
    .mockImplementation(() => undefined as never);

  try {
    await cmd.parseAsync(args, { from: "user" });
  } finally {
    mockExit.mockRestore();
  }

  return container;
}

describe("add command", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  describe("add <component>", () => {
    it("fetches component files to configured path", async () => {
      const container = await runAdd(["button"], {
        config: {
          load: vi.fn().mockResolvedValue(sampleConfig),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(sampleButton),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
        fetcher: {
          fetchComponents: vi.fn().mockResolvedValue(addedResult),
          fetchTheme: vi.fn(),
          fetchSdui: vi.fn(),
        },
      });

      expect(container.registry.getComponent).toHaveBeenCalledWith("button");
      expect(container.fetcher.fetchComponents).toHaveBeenCalledWith(
        sampleButton.files,
        expect.stringContaining("Components"),
        { force: undefined }
      );
    });
  });

  describe("add <component> with SDUI config", () => {
    it("includes SDUI files when config has sduiPath", async () => {
      const container = await runAdd(["button"], {
        config: {
          load: vi.fn().mockResolvedValue(sampleConfigWithSdui),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(sampleButton),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
        fetcher: {
          fetchComponents: vi.fn().mockResolvedValue(addedWithSduiResult),
          fetchTheme: vi.fn(),
          fetchSdui: vi.fn(),
        },
      });

      expect(container.fetcher.fetchComponents).toHaveBeenCalledWith(
        [...sampleButton.files, ...sampleButton.sdui_files!],
        expect.stringContaining("Components"),
        { force: undefined }
      );
    });
  });

  describe("--force", () => {
    it("passes force option to fetcher", async () => {
      const container = await runAdd(["button", "--force"], {
        config: {
          load: vi.fn().mockResolvedValue(sampleConfig),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(sampleButton),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
        fetcher: {
          fetchComponents: vi.fn().mockResolvedValue(addedResult),
          fetchTheme: vi.fn(),
          fetchSdui: vi.fn(),
        },
      });

      expect(container.fetcher.fetchComponents).toHaveBeenCalledWith(
        expect.any(Array),
        expect.any(String),
        { force: true }
      );
    });

    it("passes force with -f shorthand", async () => {
      const container = await runAdd(["button", "-f"], {
        config: {
          load: vi.fn().mockResolvedValue(sampleConfig),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(sampleButton),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
        fetcher: {
          fetchComponents: vi.fn().mockResolvedValue(addedResult),
          fetchTheme: vi.fn(),
          fetchSdui: vi.fn(),
        },
      });

      expect(container.fetcher.fetchComponents).toHaveBeenCalledWith(
        expect.any(Array),
        expect.any(String),
        { force: true }
      );
    });
  });

  describe("--no-sdui", () => {
    it("skips SDUI files even when config has sduiPath", async () => {
      const container = await runAdd(["button", "--no-sdui"], {
        config: {
          load: vi.fn().mockResolvedValue(sampleConfigWithSdui),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(sampleButton),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
        fetcher: {
          fetchComponents: vi.fn().mockResolvedValue(addedResult),
          fetchTheme: vi.fn(),
          fetchSdui: vi.fn(),
        },
      });

      // Should only include base files, not SDUI files
      expect(container.fetcher.fetchComponents).toHaveBeenCalledWith(
        sampleButton.files,
        expect.any(String),
        expect.any(Object)
      );
    });
  });

  describe("--force + --no-sdui", () => {
    it("force overwrites without SDUI files", async () => {
      const container = await runAdd(["button", "-f", "--no-sdui"], {
        config: {
          load: vi.fn().mockResolvedValue(sampleConfigWithSdui),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(sampleButton),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
        fetcher: {
          fetchComponents: vi.fn().mockResolvedValue(addedResult),
          fetchTheme: vi.fn(),
          fetchSdui: vi.fn(),
        },
      });

      expect(container.fetcher.fetchComponents).toHaveBeenCalledWith(
        sampleButton.files,
        expect.any(String),
        { force: true }
      );
    });
  });

  describe("fetch error", () => {
    it("exits with error when fetcher throws", async () => {
      const mockExit = vi
        .spyOn(process, "exit")
        .mockImplementation(() => {
          throw new Error("process.exit called");
        });

      const container = createMockContainer({
        config: {
          load: vi.fn().mockResolvedValue(sampleConfig),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(sampleButton),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
        fetcher: {
          fetchComponents: vi
            .fn()
            .mockRejectedValue(new Error("Network error")),
          fetchTheme: vi.fn(),
          fetchSdui: vi.fn(),
        },
      });
      const cmd = createAddCommand(container);

      try {
        await cmd.parseAsync(["button"], { from: "user" });
      } catch {
        // Expected: process.exit throws
      }

      expect(mockExit).toHaveBeenCalledWith(1);
      mockExit.mockRestore();
    });
  });

  describe("skipped files", () => {
    it("shows force hint when all files already exist", async () => {
      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      const skippedResult: FetchResult = {
        added: [],
        skipped: ["/project/Components/CNButton.swift"],
      };

      await runAdd(["button"], {
        config: {
          load: vi.fn().mockResolvedValue(sampleConfig),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(sampleButton),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
        fetcher: {
          fetchComponents: vi.fn().mockResolvedValue(skippedResult),
          fetchTheme: vi.fn(),
          fetchSdui: vi.fn(),
        },
      });

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("--force");
    });
  });

  describe("SDUI hint", () => {
    it("shows SDUI hint when component supports SDUI but config does not", async () => {
      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      await runAdd(["button"], {
        config: {
          load: vi.fn().mockResolvedValue(sampleConfig),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(sampleButton),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
        fetcher: {
          fetchComponents: vi.fn().mockResolvedValue(addedResult),
          fetchTheme: vi.fn(),
          fetchSdui: vi.fn(),
        },
      });

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("swiftcn init --sdui");
    });
  });

  describe("no config", () => {
    it("exits with error when no swiftcn.json found", async () => {
      const mockExit = vi
        .spyOn(process, "exit")
        .mockImplementation(() => {
          throw new Error("process.exit called");
        });

      const container = createMockContainer({
        config: {
          load: vi.fn().mockResolvedValue(null),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(false),
        },
      });
      const cmd = createAddCommand(container);

      try {
        await cmd.parseAsync(["button"], { from: "user" });
      } catch {
        // Expected: process.exit throws
      }

      expect(mockExit).toHaveBeenCalledWith(1);
      expect(container.fetcher.fetchComponents).not.toHaveBeenCalled();
      mockExit.mockRestore();
    });
  });

  describe("unknown component", () => {
    it("exits with error when component not found", async () => {
      const mockExit = vi
        .spyOn(process, "exit")
        .mockImplementation(() => {
          throw new Error("process.exit called");
        });

      const container = createMockContainer({
        config: {
          load: vi.fn().mockResolvedValue(sampleConfig),
          write: vi.fn(),
          exists: vi.fn().mockResolvedValue(true),
        },
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn().mockResolvedValue(null),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
      });
      const cmd = createAddCommand(container);

      try {
        await cmd.parseAsync(["nonexistent"], { from: "user" });
      } catch {
        // Expected: process.exit throws
      }

      expect(mockExit).toHaveBeenCalledWith(1);
      expect(container.registry.getComponent).toHaveBeenCalledWith(
        "nonexistent"
      );
      expect(container.fetcher.fetchComponents).not.toHaveBeenCalled();
      mockExit.mockRestore();
    });
  });

  describe("-h / --help", () => {
    it("shows help with -h", async () => {
      const container = createMockContainer();
      const program = createProgram(createAddCommand(container));
      program.exitOverride();
      program.commands.forEach((cmd) => cmd.exitOverride());

      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      try {
        await program.parseAsync(["node", "swiftcn", "add", "-h"]);
      } catch {
        // Commander throws after displaying help
      }

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("swiftcn add");
      expect(output).toContain("--force");
      expect(output).toContain("--no-sdui");
      expect(container.fetcher.fetchComponents).not.toHaveBeenCalled();
    });

    it("shows help with --help long form", async () => {
      const container = createMockContainer();
      const program = createProgram(createAddCommand(container));
      program.exitOverride();
      program.commands.forEach((cmd) => cmd.exitOverride());

      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      try {
        await program.parseAsync(["node", "swiftcn", "add", "--help"]);
      } catch {
        // Commander throws after displaying help
      }

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("swiftcn add");
      expect(container.fetcher.fetchComponents).not.toHaveBeenCalled();
    });
  });
});
