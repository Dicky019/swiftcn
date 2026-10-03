import fs from "fs-extra";
import os from "node:os";
import path from "node:path";
import { beforeEach, afterEach, describe, it, expect, vi } from "vitest";
import { createContainer } from "../../container.js";
import { createInitCommand } from "../../commands/init.js";
import { InitServiceImpl } from "../../services/InitService.js";
import { FileTransactionServiceImpl } from "../../services/FileTransactionService.js";
import { SOURCE_REF } from "../../utils/constants.js";

const repository = path.resolve(import.meta.dirname, "../../../..");

describe("init integration", () => {
  let root: string;
  let cwd: string;
  let container: ReturnType<typeof createContainer>;

  beforeEach(async () => {
    root = await fs.mkdtemp(path.join(os.tmpdir(), "swiftcn-command-"));
    cwd = path.join(root, "project");
    await fs.outputFile(path.join(cwd, "App.swift"), "app-owned");
    await fs.outputFile(path.join(cwd, "Package.swift"), "manifest-owned");
    vi.spyOn(console, "log").mockImplementation(() => {});
    vi.spyOn(process, "cwd").mockReturnValue(cwd);
    vi.spyOn(process, "exit").mockImplementation(() => undefined as never);
    container = createContainer();
    container.git.clone = vi.fn(async (_url, target, ref) => {
      expect(ref).toBe(SOURCE_REF);
      await fs.copy(path.join(repository, "Sources"), path.join(target, "Sources"));
      await fs.copy(path.join(repository, "CLI/registry.json"), path.join(target, "CLI/registry.json"));
    });
    let checkoutNumber = 0;
    container.git.createTempDir = () => path.join(root, `snapshot-${++checkoutNumber}`);
    container.initializer = new InitServiceImpl(container.git, container.file, new FileTransactionServiceImpl());
  });
  afterEach(async () => { vi.restoreAllMocks(); await fs.remove(root); });

  it.each(["native", "mvvm", "tca"] as const)("installs canonical selected files and preserves the app for %s", async (preset) => {
    await createInitCommand(container).parseAsync([
      "--preset", preset, "--path", "App/Components", "--theme-path", "App/Theme",
      "--sdui-path", "App/SDUI", "--navigation", "--offline-first", "-y",
    ], { from: "user" });
    expect(process.exit).not.toHaveBeenCalled();
    expect(await container.config.load(cwd)).toMatchObject({ preset, navigation: true, offlineFirst: true, sduiPath: "App/SDUI" });
    expect(await fs.readFile(path.join(cwd, "App.swift"), "utf8")).toBe("app-owned");
    expect(await fs.readFile(path.join(cwd, "Package.swift"), "utf8")).toBe("manifest-owned");
    expect(await fs.pathExists(path.join(cwd, "App/Features"))).toBe(false);
    expect(await fs.pathExists(path.join(cwd, "App/Navigation/Router.swift"))).toBe(preset !== "tca");
    for (const filename of ["SyncTypes.swift", "RetryPolicy.swift", "SyncCoordinator.swift"]) {
      expect(await fs.readFile(path.join(cwd, "App/OfflineFirst", filename), "utf8"))
        .toBe(await fs.readFile(path.join(repository, "Sources/OfflineFirst", filename), "utf8"));
    }
    expect(await fs.pathExists(path.join(cwd, ".swiftcn-transaction"))).toBe(false);
    expect(vi.mocked(container.git.clone)).toHaveBeenCalledTimes(1);
  });

  it("preserves custom source through rerun and negative flags, then replaces only with force", async () => {
    await createInitCommand(container).parseAsync(["--preset", "mvvm", "--navigation", "--offline-first", "-y"], { from: "user" });
    const theme = path.join(cwd, "Theme/Core/Theme.swift");
    await fs.writeFile(theme, "user-customized");
    await createInitCommand(container).parseAsync(["-y"], { from: "user" });
    expect(await container.config.load(cwd)).toMatchObject({ preset: "mvvm", navigation: true, offlineFirst: true });
    expect(await fs.readFile(theme, "utf8")).toBe("user-customized");
    await createInitCommand(container).parseAsync(["--no-navigation", "--no-offline-first", "-y"], { from: "user" });
    expect(await container.config.load(cwd)).toMatchObject({ navigation: false, offlineFirst: false });
    expect(await fs.pathExists(path.join(cwd, "Navigation/Router.swift"))).toBe(true);
    expect(await fs.pathExists(path.join(cwd, "OfflineFirst/SyncCoordinator.swift"))).toBe(true);
    await createInitCommand(container).parseAsync(["--force", "-y"], { from: "user" });
    expect(await fs.readFile(theme, "utf8")).toBe(await fs.readFile(path.join(repository, "Sources/Theme/Core/Theme.swift"), "utf8"));
    expect(process.exit).not.toHaveBeenCalled();
  });
});
