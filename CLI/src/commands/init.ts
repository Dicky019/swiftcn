import { Command } from "commander";
import * as p from "@clack/prompts";
import path from "node:path";
import { resolveSecurePath } from "../utils/paths.js";
import { ui } from "../utils/ui.js";
import { SOURCE_REF } from "../utils/constants.js";
import { InitOptionsSchema, type ArchitecturePreset } from "../types/options.schema.js";
import { projectConfigSchema, type ProjectConfig } from "../types/config.schema.js";
import type { Container } from "../container.js";

const INITIALIZATION_CANCELLED = Symbol("initialization-cancelled");

function printInitHelp() {
  ui.header();
  ui.break();
  ui.line("Usage: swiftcn init [options]");
  ui.break();
  ui.line("Configure an existing SwiftUI project and install the selected foundations.");
  ui.line("Theme files are always included. App.swift and project manifests stay yours.");
  ui.break();
  ui.section("Options");
  ui.break();
  ui.command("--preset <native|mvvm|tca>", "Architecture preset (default: native)");
  ui.command("--navigation             ", "Include preset-appropriate navigation (opt-in)");
  ui.command("--no-navigation          ", "Disable navigation in config without deleting files");
  ui.command("--offline-first          ", "Install the external-system-agnostic sync core (opt-in)");
  ui.command("--no-offline-first       ", "Disable Offline-First in config without deleting files");
  ui.command("-p, --path <path>         ", "Components directory (default: Components)");
  ui.command("--theme-path <path>       ", "Theme directory (default: Theme)");
  ui.command("--sdui                    ", "Include SDUI infrastructure");
  ui.command("--sdui-path <path>        ", "SDUI directory (default: SDUI; implies --sdui)");
  ui.command("-f, --force               ", "Replace existing foundation files");
  ui.command("-y, --yes                 ", "Skip prompts; preserve existing selections on rerun");
  ui.command("-h, --help                ", "Show help for init command");
  ui.break();
  ui.section("Examples");
  ui.break();
  ui.command("swiftcn init -y", "Initialize with Native and opt-out capabilities");
  ui.command("swiftcn init --preset mvvm --navigation -y", "Install the existing SwiftUI Router");
  ui.command("swiftcn init --preset tca --navigation -y", "Use TCA navigation state; installs no Router");
  ui.command("swiftcn init --preset native --offline-first -y", "Install sync contracts, retry policy and coordinator");
  ui.command("swiftcn init -p App/Components --theme-path App/Theme --sdui-path App/SDUI", "Use custom foundation paths");
  ui.break();
  ui.hint("Reruns preserve omitted options. --force replaces conflicts; otherwise files are skipped.");
  ui.end(`Run ${ui.accent("swiftcn add <component>")} after init to add components.`);
}

function printNextSteps(config: ProjectConfig) {
  ui.section("Next steps");
  ui.break();
  ui.command("swiftcn add button", "Add your first component");
  ui.command("swiftcn list", "Browse all components");
  ui.break();
  switch (config.preset) {
    case "native":
      ui.hint("View owns local @State and calls a use case directly; business rules stay in Domain.");
      if (config.navigation) ui.hint("Own one Router<AppRoute> at the flow root and inject it into the environment.");
      break;
    case "mvvm":
      ui.hint("An @MainActor @Observable ViewModel owns screen state and emits typed navigation outcomes.");
      if (config.navigation) ui.hint("The flow owner validates outcomes and updates Router<AppRoute>.");
      break;
    case "tca":
      ui.hint("The Store and reducer own presentation state, actions, and effects; use cases depend inward.");
      if (config.navigation) ui.hint("Own navigation with StackState and @Presents in reducer state.");
      break;
  }
  ui.line(`https://github.com/Dicky019/swiftcn/blob/${SOURCE_REF}/docs/architecture-presets.md#${config.preset}`);
  if (config.offlineFirst) {
    ui.hint("Integrate a durable local adapter and external gateway through your feature's SyncWorker.");
    ui.line(`https://github.com/Dicky019/swiftcn/blob/${SOURCE_REF}/docs/offline-first.md`);
  }
  ui.break();
  ui.hint("Add ThemeProvider to your App:");
  ui.line("  @State private var themeProvider = ThemeProvider()");
  ui.line("  ContentView()");
  ui.line("      .environment(themeProvider)");
  ui.line("      .withThemeTracking(themeProvider)");
  ui.break();
  ui.hint("Components are copied to your project — you own the code!");
  ui.end("Happy coding!");
}

export function createInitCommand(container: Container): Command {
  const cmd = new Command()
    .name("init")
    .description("Initialize swiftcn in your project")
    .helpOption("-h, --help", "Show help for init command")
    .option("--preset <preset>", "Architecture preset: native, mvvm, or tca")
    .option("--navigation", "Include preset-appropriate navigation")
    .option("--no-navigation", "Disable navigation in config without deleting files")
    .option("--offline-first", "Install the external-system-agnostic sync core")
    .option("--no-offline-first", "Disable Offline-First in config without deleting files")
    .option("-p, --path <path>", "Path to components directory")
    .option("--theme-path <path>", "Path to theme directory")
    .option("--sdui", "Include SDUI infrastructure")
    .option("--sdui-path <path>", "Path to SDUI directory")
    .option("-f, --force", "Replace existing foundation files")
    .option("-y, --yes", "Skip prompts and preserve existing selections")
    .action(async (rawOptions) => {
      ui.header();
      try {
        const options = InitOptionsSchema.parse(rawOptions);
        const cwd = process.cwd();
        await container.initializer.recover(cwd);
        const loaded = await container.config.load(cwd);
        const existing = loaded ? projectConfigSchema.parse(loaded) : null;
        let componentsPath = rawOptions.path ?? existing?.componentsPath ?? options.path;
        let themePath = rawOptions.themePath ?? existing?.themePath ?? options.themePath;
        let sduiPath = rawOptions.sduiPath ?? existing?.sduiPath ?? options.sduiPath;
        let withSdui = options.sdui ?? Boolean(rawOptions.sduiPath || existing?.sduiPath);
        let preset = options.preset ?? existing?.preset ?? "native";
        let navigation = options.navigation ?? existing?.navigation ?? false;
        let offlineFirst = options.offlineFirst ?? existing?.offlineFirst ?? false;

        if (!options.yes) {
          const answers = await p.group({
            preset: () => options.preset !== undefined ? Promise.resolve(preset) : p.select({
              message: "Which architecture preset?", initialValue: preset,
              options: [
                { value: "native", label: "Native", hint: "View owns local state" },
                { value: "mvvm", label: "MVVM", hint: "Observable ViewModel owns screen state" },
                { value: "tca", label: "TCA", hint: "Reducer owns state and effects; Swift 6.1+" },
              ],
            }),
            componentsPath: () => rawOptions.path !== undefined ? Promise.resolve(componentsPath) : p.text({
              message: "Where would you like to store components?", initialValue: componentsPath,
              validate: (value) => !value ? "Path is required" : undefined,
            }),
            themePath: () => rawOptions.themePath !== undefined ? Promise.resolve(themePath) : p.text({
              message: "Where would you like to store theme files?", initialValue: themePath,
              validate: (value) => !value ? "Path is required" : undefined,
            }),
            withSdui: () => options.sdui !== undefined || rawOptions.sduiPath !== undefined
              ? Promise.resolve(withSdui) : p.confirm({ message: "Include SDUI infrastructure?", initialValue: withSdui }),
            sduiPath: ({ results }) => results.withSdui && rawOptions.sduiPath === undefined
              ? p.text({ message: "Where would you like to store SDUI files?", initialValue: sduiPath,
                  validate: (value) => !value ? "Path is required" : undefined })
              : Promise.resolve(sduiPath),
            navigation: () => options.navigation !== undefined ? Promise.resolve(navigation)
              : p.confirm({ message: "Include navigation?", initialValue: navigation }),
            offlineFirst: () => options.offlineFirst !== undefined ? Promise.resolve(offlineFirst)
              : p.confirm({ message: "Include Offline-First Core?", initialValue: offlineFirst }),
          }, { onCancel: () => {
            p.cancel("Initialization cancelled.");
            // Clack 0.7 continues the group if this callback returns.
            throw INITIALIZATION_CANCELLED;
          } });
          if (p.isCancel(answers)) return;
          componentsPath = answers.componentsPath;
          themePath = answers.themePath;
          withSdui = answers.withSdui;
          sduiPath = answers.sduiPath;
          preset = answers.preset as ArchitecturePreset;
          navigation = answers.navigation;
          offlineFirst = answers.offlineFirst;
        }
        resolveSecurePath(cwd, componentsPath);
        resolveSecurePath(cwd, themePath);
        if (withSdui) resolveSecurePath(cwd, sduiPath);
        const config = projectConfigSchema.parse({
          ...existing, componentsPath, themePath, sduiPath: withSdui ? sduiPath : undefined,
          preset, navigation, offlineFirst,
        });
        if (existing && existing.preset !== config.preset) {
          ui.hint(`Changing preset from ${existing.preset} to ${config.preset} does not migrate existing feature source.`);
        }
        if (config.preset === "tca") {
          ui.hint("TCA 1.26.1 requires Swift 6.1+. Add the dependency in your project before using the recipe.");
        }
        ui.break();
        ui.step("Installing selected foundations...");
        const result = await container.initializer.initialize({
          cwd, config, includeSdui: Boolean(config.sduiPath),
          includeNavigationRouter: config.navigation && config.preset !== "tca",
          includeOfflineFirst: config.offlineFirst, force: options.force,
        });
        for (const file of result.added) ui.fileAdded(path.relative(cwd, file));
        for (const file of result.replaced) ui.line(`Replaced ${path.relative(cwd, file)}`);
        for (const file of result.skipped) ui.fileExists(path.relative(cwd, file));
        ui.break();
        ui.success("Project initialized!");
        ui.break();
        printNextSteps(config);
      } catch (error) {
        if (error === INITIALIZATION_CANCELLED) return;
        ui.error("Failed to initialize project");
        ui.line(error instanceof Error ? error.message : String(error));
        ui.end();
        process.exit(1);
      }
    });

  cmd.configureOutput({ writeOut: () => { printInitHelp(); } });
  return cmd;
}
