import { describe, it, expect, vi, beforeEach } from "vitest";
import { createListCommand } from "../../commands/list.js";
import type { Container } from "../../container.js";
import {
  createMockContainer,
  createProgram,
  sampleComponents,
} from "./helpers.js";

async function runList(
  args: string[],
  containerOverrides: Partial<Container> = {}
) {
  const container = createMockContainer(containerOverrides);
  const cmd = createListCommand(container);

  const mockExit = vi
    .spyOn(process, "exit")
    .mockImplementation(() => undefined as never);

  try {
    await cmd.parseAsync(["node", "list", ...args], { from: "user" });
  } finally {
    mockExit.mockRestore();
  }

  return container;
}

describe("list command", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  describe("list (default)", () => {
    it("lists components from registry", async () => {
      const container = await runList([], {
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn(),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
      });

      expect(container.registry.listComponents).toHaveBeenCalled();
    });

    it("displays component names in output", async () => {
      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      await runList([], {
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn(),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
      });

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("button");
      expect(output).toContain("CNButton");
      expect(output).toContain("card");
      expect(output).toContain("CNCard");
    });
  });

  describe("--verbose", () => {
    it("shows detailed component information", async () => {
      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      await runList(["--verbose"], {
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn(),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
      });

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("Variants:");
      expect(output).toContain("Sizes:");
      expect(output).toContain("SDUI:");
    });

    it("shows verbose with -v shorthand", async () => {
      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      await runList(["-v"], {
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn(),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
      });

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("Variants:");
    });

    it("shows usage hints in verbose mode", async () => {
      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      await runList(["--verbose"], {
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn(),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
      });

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("swiftcn add button");
      expect(output).toContain("2 components available");
    });
  });

  describe("compact mode (no --verbose)", () => {
    it("does not show variants/sizes details", async () => {
      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      await runList([], {
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn(),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
      });

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).not.toContain("Variants:");
      expect(output).not.toContain("Sizes:");
    });

    it("shows SDUI hint", async () => {
      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      await runList([], {
        registry: {
          load: vi.fn().mockResolvedValue({}),
          getComponent: vi.fn(),
          listComponents: vi.fn().mockResolvedValue(sampleComponents),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
      });

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("SDUI-compatible");
    });
  });

  describe("registry error", () => {
    it("exits with error when registry fails to load", async () => {
      const mockExit = vi
        .spyOn(process, "exit")
        .mockImplementation(() => undefined as never);

      const container = createMockContainer({
        registry: {
          load: vi.fn().mockRejectedValue(new Error("Network error")),
          getComponent: vi.fn(),
          listComponents: vi
            .fn()
            .mockRejectedValue(new Error("Network error")),
          getThemeFiles: vi.fn().mockResolvedValue([]),
          getSduiFiles: vi.fn().mockResolvedValue([]),
        },
      });
      const cmd = createListCommand(container);

      await cmd.parseAsync(["node", "list"], { from: "user" });

      expect(mockExit).toHaveBeenCalledWith(1);
      mockExit.mockRestore();
    });
  });

  describe("-h / --help", () => {
    it("shows help with -h", async () => {
      const container = createMockContainer();
      const program = createProgram(createListCommand(container));
      program.exitOverride();
      program.commands.forEach((cmd) => cmd.exitOverride());

      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      try {
        await program.parseAsync(["node", "swiftcn", "list", "-h"]);
      } catch {
        // Commander throws after displaying help
      }

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("swiftcn list");
      expect(output).toContain("--verbose");
      expect(container.registry.listComponents).not.toHaveBeenCalled();
    });

    it("shows help with --help long form", async () => {
      const container = createMockContainer();
      const program = createProgram(createListCommand(container));
      program.exitOverride();
      program.commands.forEach((cmd) => cmd.exitOverride());

      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      try {
        await program.parseAsync(["node", "swiftcn", "list", "--help"]);
      } catch {
        // Commander throws after displaying help
      }

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("swiftcn list");
      expect(container.registry.listComponents).not.toHaveBeenCalled();
    });
  });
});
