import fs from "fs-extra";
import os from "node:os";
import path from "node:path";
import { beforeEach, afterEach, describe, it, expect, vi } from "vitest";
import { InitServiceImpl } from "../../services/InitService.js";
import { FileServiceImpl } from "../../services/FileService.js";
import { FileTransactionServiceImpl } from "../../services/FileTransactionService.js";
import { projectConfigSchema } from "../../types/config.schema.js";
import type { GitService } from "../../services/GitService.js";
import { SOURCE_REF } from "../../utils/constants.js";

const repository = path.resolve(import.meta.dirname, "../../../..");

describe("InitServiceImpl", () => {
  let root: string;
  let cwd: string;
  let checkout: string;
  let git: GitService;
  let service: InitServiceImpl;
  let registry: any;
  const config = projectConfigSchema.parse({ componentsPath: "App/Components", themePath: "App/Theme", sduiPath: "App/SDUI" });

  beforeEach(async () => {
    root = await fs.mkdtemp(path.join(os.tmpdir(), "swiftcn-plan-"));
    cwd = path.join(root, "project");
    checkout = path.join(root, "checkout");
    await fs.ensureDir(cwd);
    registry = await fs.readJson(path.join(repository, "CLI/registry.json"));
    git = {
      createTempDir: () => checkout,
      clone: vi.fn(async () => {
        await fs.outputJson(path.join(checkout, "CLI/registry.json"), registry);
        const sources = [
          ...registry.theme.core, ...registry.theme.palettes, ...registry.theme.provider,
          ...registry.sdui.core, ...registry.sdui.wrappers,
          ...registry.components.navigation.files,
          ...(registry.offlineFirst?.core ?? []),
        ];
        for (const source of sources) {
          await fs.outputFile(path.join(checkout, "Sources", source), source);
        }
      }),
      cleanup: vi.fn(async () => { await fs.remove(checkout); }),
    };
    service = new InitServiceImpl(git, new FileServiceImpl(), new FileTransactionServiceImpl());
  });

  afterEach(async () => { vi.restoreAllMocks(); await fs.remove(root); });

  const options = () => ({ cwd, config, includeSdui: true, includeNavigationRouter: true, includeOfflineFirst: false });

  it("installs theme, SDUI and the exact registry Router from one tagged snapshot", async () => {
    const result = await service.initialize(options());
    expect(git.clone).toHaveBeenCalledExactlyOnceWith(expect.any(String), checkout, SOURCE_REF);
    expect(await fs.readFile(path.join(cwd, "App/Theme/Core/Theme.swift"), "utf8")).toBe("Theme/Core/Theme.swift");
    expect(await fs.readFile(path.join(cwd, "App/Navigation/Router.swift"), "utf8")).toBe("Navigation/Router.swift");
    expect(await fs.readFile(path.join(cwd, "App/SDUI/Core/SDUINode.swift"), "utf8")).toBe("SDUI/Core/SDUINode.swift");
    expect(await fs.readJson(path.join(cwd, "swiftcn.json"))).toEqual(config);
    expect(result.added).toContain(path.join(cwd, "App/Navigation/Router.swift"));
    expect(await fs.pathExists(checkout)).toBe(false);
  });

  it.each(["native", "mvvm", "tca"] as const)("installs identical optional core for %s", async (preset) => {
    await service.initialize({ ...options(), config: { ...config, preset, offlineFirst: true }, includeNavigationRouter: preset !== "tca", includeOfflineFirst: true });
    for (const file of ["SyncTypes.swift", "RetryPolicy.swift", "SyncCoordinator.swift"]) {
      expect(await fs.readFile(path.join(cwd, "App/OfflineFirst", file), "utf8")).toBe(`OfflineFirst/${file}`);
    }
    expect(await fs.pathExists(path.join(cwd, "App/Navigation/Router.swift"))).toBe(preset !== "tca");
  });

  it("never installs Router for TCA even if its caller requests it", async () => {
    await service.initialize({ ...options(), config: { ...config, preset: "tca", navigation: true } });
    expect(await fs.pathExists(path.join(cwd, "App/Navigation"))).toBe(false);
  });

  it("keeps owned source on rerun and disabling capabilities", async () => {
    await service.initialize({ ...options(), includeOfflineFirst: true });
    const owned = path.join(cwd, "App/Theme/Core/Theme.swift");
    await fs.writeFile(owned, "owned");
    const result = await service.initialize({ ...options(), includeNavigationRouter: false, includeOfflineFirst: false });
    expect(result.skipped).toContain(owned);
    expect(await fs.readFile(owned, "utf8")).toBe("owned");
    expect(await fs.pathExists(path.join(cwd, "App/OfflineFirst/SyncCoordinator.swift"))).toBe(true);
    expect(await fs.pathExists(path.join(cwd, "App/Navigation/Router.swift"))).toBe(true);
  });

  it("replaces conflicts only with force", async () => {
    await service.initialize(options());
    const owned = path.join(cwd, "App/Theme/Core/Theme.swift");
    await fs.writeFile(owned, "owned");
    const result = await service.initialize({ ...options(), force: true });
    expect(result.replaced).toContain(owned);
    expect(await fs.readFile(owned, "utf8")).toBe("Theme/Core/Theme.swift");
  });

  it.each(["../outside", "/tmp/outside"])("rejects destination %s before cloning", async (themePath) => {
    await expect(service.initialize({ ...options(), config: { ...config, themePath } })).rejects.toThrow();
    expect(git.clone).not.toHaveBeenCalled();
    expect(await fs.readdir(cwd)).toEqual([]);
  });

  it("rejects invalid preset before cloning", async () => {
    await expect(service.initialize({ ...options(), config: { ...config, preset: "viper" as any } })).rejects.toThrow();
    expect(git.clone).not.toHaveBeenCalled();
  });

  it("rejects a wrong registry prefix without writing the project", async () => {
    registry.theme.core[0] = "SDUI/Core/Theme.swift";
    await expect(service.initialize(options())).rejects.toThrow("Theme/");
    expect(await fs.readdir(cwd)).toEqual([]);
    expect(await fs.pathExists(checkout)).toBe(false);
  });

  it("rejects a source escape before any file installation", async () => {
    registry.theme.core[0] = "Theme/../../../outside.swift";
    await expect(service.initialize(options())).rejects.toThrow();
    expect(await fs.readdir(cwd)).toEqual([]);
  });

  it("rejects missing source files before any file installation", async () => {
    const clone = git.clone;
    git.clone = async (...args) => {
      await clone(...args);
      await fs.remove(path.join(checkout, "Sources", registry.theme.core[0]));
    };
    await expect(service.initialize(options())).rejects.toThrow("source");
    expect(await fs.readdir(cwd)).toEqual([]);
    expect(await fs.pathExists(checkout)).toBe(false);
  });

  it("cleans up a failed clone", async () => {
    git.clone = async () => { await fs.ensureDir(checkout); throw new Error("offline"); };
    await expect(service.initialize(options())).rejects.toThrow("offline");
    expect(await fs.pathExists(checkout)).toBe(false);
    expect(await fs.readdir(cwd)).toEqual([]);
  });

  it("refuses a live transaction before network work", async () => {
    await fs.outputJson(path.join(cwd, ".swiftcn-transaction/journal.json"), {
      version: 1, ownerPid: process.pid, state: "staging", entries: [],
    });
    await expect(service.initialize(options())).rejects.toThrow("already running");
    expect(git.clone).not.toHaveBeenCalled();
  });

  it("supports a legacy release without Offline-First only when the capability is disabled", async () => {
    delete registry.offlineFirst;
    await expect(service.initialize({ ...options(), includeOfflineFirst: true })).rejects.toThrow("unavailable");
    expect(await fs.readdir(cwd)).toEqual([]);
    await service.initialize({ ...options(), includeOfflineFirst: false });
    expect(await fs.pathExists(path.join(cwd, "App/Theme/Core/Theme.swift"))).toBe(true);
  });

  it("requires the exact Router manifest only for native/MVVM navigation", async () => {
    registry.components.navigation.files.push("Components/CNButton.swift");
    await expect(service.initialize(options())).rejects.toThrow("Navigation/Router.swift");
    expect(await fs.readdir(cwd)).toEqual([]);
    await service.initialize({ ...options(), config: { ...config, preset: "tca" } });
    expect(await fs.pathExists(path.join(cwd, "App/Navigation"))).toBe(false);
  });
});
