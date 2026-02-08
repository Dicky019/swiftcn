import { describe, it, expect, vi, beforeEach } from "vitest";
import { createInitCommand } from "../../commands/init.js";
import type { Container } from "../../container.js";
import { createMockContainer, createProgram } from "./helpers.js";

async function runInit(
  args: string[],
  containerOverrides: Partial<Container> = {}
) {
  const container = createMockContainer(containerOverrides);
  const cmd = createInitCommand(container);

  const mockExit = vi
    .spyOn(process, "exit")
    .mockImplementation(() => undefined as never);

  try {
    await cmd.parseAsync(["node", "init", ...args], { from: "user" });
  } finally {
    mockExit.mockRestore();
  }

  return container;
}

describe("init command", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  describe("--path", () => {
    it("uses custom components path", async () => {
      const container = await runInit(["--path", "App/Components", "-y"]);

      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({ componentsPath: "App/Components" }),
        expect.any(String)
      );
    });

    it("uses -p shorthand", async () => {
      const container = await runInit(["-p", "App/UI", "-y"]);

      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({ componentsPath: "App/UI" }),
        expect.any(String)
      );
    });
  });

  describe("--theme-path", () => {
    it("uses custom theme path", async () => {
      const container = await runInit(["--theme-path", "App/Theme", "-y"]);

      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({ themePath: "App/Theme" }),
        expect.any(String)
      );
    });
  });

  describe("--sdui", () => {
    it("enables SDUI infrastructure", async () => {
      const container = await runInit(["--sdui", "-y"]);

      expect(container.fetcher.fetchSdui).toHaveBeenCalled();
      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({ sduiPath: "SDUI" }),
        expect.any(String)
      );
    });
  });

  describe("--sdui-path", () => {
    it("uses custom SDUI path and implies --sdui", async () => {
      const container = await runInit(["--sdui-path", "App/SDUI", "-y"]);

      expect(container.fetcher.fetchSdui).toHaveBeenCalled();
      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({ sduiPath: "App/SDUI" }),
        expect.any(String)
      );
    });
  });

  describe("--path + --theme-path", () => {
    it("uses both custom paths", async () => {
      const container = await runInit([
        "--path", "App/Components",
        "--theme-path", "App/Theme",
        "-y",
      ]);

      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({
          componentsPath: "App/Components",
          themePath: "App/Theme",
        }),
        expect.any(String)
      );
    });
  });

  describe("--path + --theme-path + --sdui", () => {
    it("uses custom paths with SDUI enabled", async () => {
      const container = await runInit([
        "--path", "App/Components",
        "--theme-path", "App/Theme",
        "--sdui",
        "-y",
      ]);

      expect(container.fetcher.fetchSdui).toHaveBeenCalled();
      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({
          componentsPath: "App/Components",
          themePath: "App/Theme",
          sduiPath: "SDUI",
        }),
        expect.any(String)
      );
    });
  });

  describe("--path + --theme-path + --sdui-path", () => {
    it("uses all custom paths with SDUI implied", async () => {
      const container = await runInit([
        "--path", "App/Components",
        "--theme-path", "App/Theme",
        "--sdui-path", "App/SDUI",
        "-y",
      ]);

      expect(container.fetcher.fetchSdui).toHaveBeenCalled();
      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({
          componentsPath: "App/Components",
          themePath: "App/Theme",
          sduiPath: "App/SDUI",
        }),
        expect.any(String)
      );
    });
  });

  describe("defaults", () => {
    it("uses default paths when no flags passed", async () => {
      const container = await runInit(["-y"]);

      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({
          componentsPath: "Components",
          themePath: "Theme",
          prefix: "CN",
        }),
        expect.any(String)
      );
    });

    it("does not enable SDUI by default", async () => {
      const container = await runInit(["-y"]);

      expect(container.fetcher.fetchSdui).not.toHaveBeenCalled();
      expect(container.config.write).toHaveBeenCalledWith(
        expect.objectContaining({ sduiPath: undefined }),
        expect.any(String)
      );
    });

    it("always installs theme files", async () => {
      const container = await runInit(["-y"]);

      expect(container.fetcher.fetchTheme).toHaveBeenCalled();
    });
  });

  describe("error handling", () => {
    it("exits with error when fetcher throws", async () => {
      const mockExit = vi
        .spyOn(process, "exit")
        .mockImplementation(() => undefined as never);

      const container = createMockContainer({
        fetcher: {
          fetchComponents: vi.fn(),
          fetchTheme: vi.fn().mockRejectedValue(new Error("Network error")),
          fetchSdui: vi.fn(),
        },
      });
      const cmd = createInitCommand(container);

      await cmd.parseAsync(["node", "init", "-y"], { from: "user" });

      expect(mockExit).toHaveBeenCalledWith(1);
      mockExit.mockRestore();
    });
  });

  describe("-h / --help", () => {
    it("shows help with -h and does not run init logic", async () => {
      const container = createMockContainer();
      const program = createProgram(createInitCommand(container));
      program.exitOverride();
      program.commands.forEach((cmd) => cmd.exitOverride());

      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      try {
        await program.parseAsync(["node", "swiftcn", "init", "-h"]);
      } catch {
        // Commander throws after displaying help
      }

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("Usage: swiftcn init [options]");
      expect(output).toContain("--path");
      expect(output).toContain("--theme-path");
      expect(output).toContain("--sdui");
      expect(output).toContain("--sdui-path");

      expect(container.config.write).not.toHaveBeenCalled();
      expect(container.fetcher.fetchTheme).not.toHaveBeenCalled();
    });

    it("shows help with --help long form", async () => {
      const container = createMockContainer();
      const program = createProgram(createInitCommand(container));
      program.exitOverride();
      program.commands.forEach((cmd) => cmd.exitOverride());

      const logSpy = vi
        .spyOn(console, "log")
        .mockImplementation(() => {});

      try {
        await program.parseAsync(["node", "swiftcn", "init", "--help"]);
      } catch {
        // Commander throws after displaying help
      }

      const output = logSpy.mock.calls.map((c) => c[0]).join("\n");
      expect(output).toContain("Usage: swiftcn init [options]");
      expect(container.config.write).not.toHaveBeenCalled();
    });
  });
});
