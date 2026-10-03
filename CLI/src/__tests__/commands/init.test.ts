import { describe, it, expect, vi, beforeEach } from "vitest";
import * as p from "@clack/prompts";
import { createInitCommand } from "../../commands/init.js";
import { createMockContainer, createProgram, sampleConfig } from "./helpers.js";
import type { Container } from "../../container.js";

vi.mock("@clack/prompts", () => ({
  group: vi.fn(), text: vi.fn(), confirm: vi.fn(), select: vi.fn(), cancel: vi.fn(),
  isCancel: (value: unknown) => typeof value === "symbol",
}));

async function runInit(args: string[], overrides: Partial<Container> = {}) {
  const container = createMockContainer(overrides);
  await createInitCommand(container).parseAsync(args, { from: "user" });
  return container;
}

const existing = (value: object) => ({
  load: vi.fn().mockResolvedValue(value), write: vi.fn(), exists: vi.fn().mockResolvedValue(true),
});
const output = () => vi.mocked(console.log).mock.calls.flat().join("\n");

describe("init command", () => {
  beforeEach(() => {
    vi.restoreAllMocks();
    vi.clearAllMocks();
    vi.spyOn(console, "log").mockImplementation(() => {});
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    vi.mocked(p.group).mockImplementation(async (fields: any, options: any) => {
      const results: Record<string, unknown> = {};
      for (const [key, field] of Object.entries(fields)) {
        const answer = await (field as Function)({ results });
        if (p.isCancel(answer)) {
          options.onCancel({ results });
          return Symbol("cancelled");
        }
        results[key] = answer;
      }
      return results as any;
    });
    vi.mocked(p.text).mockImplementation(async ({ initialValue }) => initialValue ?? "");
    vi.mocked(p.confirm).mockImplementation(async ({ initialValue }) => initialValue ?? false);
    vi.mocked(p.select).mockImplementation(async ({ initialValue }) => initialValue as any);
  });

  it("uses safe fresh defaults and installs through one initializer", async () => {
    const c = await runInit(["-y"]);
    expect(c.initializer.initialize).toHaveBeenCalledExactlyOnceWith({
      cwd: process.cwd(), config: { ...sampleConfig, sduiPath: undefined },
      includeSdui: false, includeNavigationRouter: false, includeOfflineFirst: false, force: undefined,
    });
    expect(c.config.write).not.toHaveBeenCalled();
    expect(c.fetcher.fetchTheme).not.toHaveBeenCalled();
    expect(c.fetcher.fetchSdui).not.toHaveBeenCalled();
    expect(c.file.ensureDir).not.toHaveBeenCalled();
  });

  it.each(["native", "mvvm", "tca"] as const)("handles every capability combination for %s", async (preset) => {
    for (const navigation of [false, true]) {
      for (const offlineFirst of [false, true]) {
        const c = await runInit(["--preset", preset, navigation ? "--navigation" : "--no-navigation", offlineFirst ? "--offline-first" : "--no-offline-first", "-y"]);
        expect(c.initializer.initialize).toHaveBeenCalledWith(expect.objectContaining({
          config: expect.objectContaining({ preset, navigation, offlineFirst }),
          includeNavigationRouter: navigation && preset !== "tca", includeOfflineFirst: offlineFirst,
        }));
      }
    }
  });

  it.each([
    [["-p", "App/UI"], { componentsPath: "App/UI" }],
    [["--path", "App/Components"], { componentsPath: "App/Components" }],
    [["--theme-path", "App/Theme"], { themePath: "App/Theme" }],
    [["--sdui"], { sduiPath: "SDUI" }],
    [["--sdui-path", "App/SDUI"], { sduiPath: "App/SDUI" }],
  ])("honors path and SDUI flags %j", async (args, config) => {
    const c = await runInit([...(args as string[]), "-y"]);
    expect(c.initializer.initialize).toHaveBeenCalledWith(expect.objectContaining({ config: expect.objectContaining(config) }));
  });

  it("preserves all existing selections, paths, prefix, and tokens on omitted rerun flags", async () => {
    const config = { ...sampleConfig, componentsPath: "App/UI", themePath: "App/Theme", sduiPath: "App/SDUI", tokensPath: "OldTokens", prefix: "OWN", preset: "mvvm", navigation: true, offlineFirst: true };
    const c = await runInit(["-y"], { config: existing(config) });
    expect(c.initializer.initialize).toHaveBeenCalledWith(expect.objectContaining({ config, includeSdui: true, includeNavigationRouter: true, includeOfflineFirst: true }));
    expect(p.confirm).not.toHaveBeenCalled();
  });

  it("reads legacy config with safe capability defaults", async () => {
    const c = await runInit(["-y"], { config: existing({ componentsPath: "App/UI", prefix: "CN" }) });
    expect(c.initializer.initialize).toHaveBeenCalledWith(expect.objectContaining({ config: expect.objectContaining({ componentsPath: "App/UI", preset: "native", navigation: false, offlineFirst: false }) }));
  });

  it("disables explicit negative flags without deleting user-owned files", async () => {
    const c = await runInit(["--no-navigation", "--no-offline-first", "-y"], { config: existing({ ...sampleConfig, navigation: true, offlineFirst: true }) });
    expect(c.initializer.initialize).toHaveBeenCalledWith(expect.objectContaining({ includeNavigationRouter: false, includeOfflineFirst: false, config: expect.objectContaining({ navigation: false, offlineFirst: false }) }));
    expect(c.file.copy).not.toHaveBeenCalled();
  });

  it.each(["-f", "--force"])("passes explicit %s to the transaction", async (flag) => {
    const c = await runInit([flag, "-y"]);
    expect(c.initializer.initialize).toHaveBeenCalledWith(expect.objectContaining({ force: true }));
  });

  it("rejects invalid preset before recovery, clone or initialization", async () => {
    const c = createMockContainer();
    await createInitCommand(c).parseAsync(["--preset", "viper", "-y"], { from: "user" });
    expect(process.exit).toHaveBeenCalledWith(1);
    expect(c.initializer.recover).not.toHaveBeenCalled();
    expect(c.initializer.initialize).not.toHaveBeenCalled();
  });

  it.each([["--path", "../outside"], ["--theme-path", "/tmp/theme"], ["--sdui-path", "../outside"]])("rejects unsafe path %s before initialization", async (flag, value) => {
    const c = await runInit([flag, value, "-y"]);
    expect(c.initializer.initialize).not.toHaveBeenCalled();
    expect(process.exit).toHaveBeenCalledWith(1);
  });

  it("recovers interrupted transactions before reading config", async () => {
    const events: string[] = [];
    const c = createMockContainer();
    vi.mocked(c.initializer.recover).mockImplementation(async () => { events.push("recover"); });
    vi.mocked(c.config.load).mockImplementation(async () => { events.push("load"); return null; });
    await createInitCommand(c).parseAsync(["-y"], { from: "user" });
    expect(events).toEqual(["recover", "load"]);
  });

  it("warns before applying a changed preset", async () => {
    const c = createMockContainer({ config: existing(sampleConfig) });
    vi.mocked(c.initializer.initialize).mockImplementation(async () => {
      expect(output()).toContain("does not migrate existing feature source");
      return { added: [], skipped: [], replaced: [] };
    });
    await createInitCommand(c).parseAsync(["--preset", "mvvm", "-y"], { from: "user" });
    expect(c.initializer.initialize).toHaveBeenCalled();
  });

  it("prints TCA dependency guidance before applying files", async () => {
    const c = createMockContainer();
    vi.mocked(c.initializer.initialize).mockImplementation(async () => {
      expect(output()).toContain("TCA 1.26.1 requires Swift 6.1");
      return { added: [], skipped: [], replaced: [] };
    });
    await createInitCommand(c).parseAsync(["--preset", "tca", "-y"], { from: "user" });
    expect(process.exit).not.toHaveBeenCalled();
  });

  it("offers interactive selections with existing values as defaults", async () => {
    const config = { ...sampleConfig, preset: "mvvm", navigation: true, offlineFirst: true };
    const c = await runInit([], { config: existing(config) });
    expect(p.select).toHaveBeenCalledWith(expect.objectContaining({ initialValue: "mvvm" }));
    expect(p.confirm).toHaveBeenCalledWith(expect.objectContaining({ message: "Include navigation?", initialValue: true }));
    expect(p.confirm).toHaveBeenCalledWith(expect.objectContaining({ message: "Include Offline-First Core?", initialValue: true }));
    expect(c.initializer.initialize).toHaveBeenCalledWith(expect.objectContaining({ config: expect.objectContaining(config) }));
  });

  it("never prompts for explicitly negated capabilities", async () => {
    await runInit(["--preset", "tca", "--no-navigation", "--no-offline-first"]);
    expect(p.select).not.toHaveBeenCalled();
    const messages = vi.mocked(p.confirm).mock.calls.map(([value]) => value.message);
    expect(messages).not.toContain("Include navigation?");
    expect(messages).not.toContain("Include Offline-First Core?");
  });

  it("cancels before any installation", async () => {
    vi.mocked(p.select).mockResolvedValue(Symbol("cancelled"));
    const c = await runInit([]);
    expect(p.cancel).toHaveBeenCalled();
    expect(c.initializer.initialize).not.toHaveBeenCalled();
    expect(c.file.ensureDir).not.toHaveBeenCalled();
  });

  it("reports transaction failures without success output", async () => {
    const c = createMockContainer();
    vi.mocked(c.initializer.initialize).mockRejectedValue(new Error("disk full"));
    await createInitCommand(c).parseAsync(["-y"], { from: "user" });
    expect(process.exit).toHaveBeenCalledWith(1);
    expect(output()).toContain("disk full");
    expect(output()).not.toContain("Project initialized!");
  });

  it.each([
    ["native", "View owns local @State"], ["mvvm", "@MainActor @Observable"], ["tca", "TCA 1.26.1 requires Swift 6.1"],
  ])("prints correct %s integration guidance", async (preset, hint) => {
    await runInit(["--preset", preset, "--navigation", "--offline-first", "-y"]);
    expect(output()).toContain(hint);
    expect(output()).toContain("architecture-presets.md");
    expect(output()).toContain("durable local adapter");
    expect(output()).toContain(".environment(themeProvider)");
    expect(output()).toContain(".withThemeTracking(themeProvider)");
    if (preset === "tca") expect(output()).toContain("StackState and @Presents");
  });

  it.each(["-h", "--help"])("shows %s without initializing", async (flag) => {
    const c = createMockContainer();
    const program = createProgram(createInitCommand(c));
    program.exitOverride(); program.commands.forEach((cmd) => cmd.exitOverride());
    await expect(program.parseAsync(["node", "swiftcn", "init", flag])).rejects.toThrow();
    expect(output()).toContain("Usage: swiftcn init [options]");
    for (const option of ["--preset", "--navigation", "--no-navigation", "--offline-first", "--no-offline-first", "--path", "--sdui", "--force"]) expect(output()).toContain(option);
    expect(c.initializer.initialize).not.toHaveBeenCalled();
    expect(c.initializer.recover).not.toHaveBeenCalled();
  });
});
