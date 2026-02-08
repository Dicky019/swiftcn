import { Command } from "commander";
import * as p from "@clack/prompts";
import path from "node:path";
import { ui } from "../utils/ui.js";
import { InitOptionsSchema } from "../types/options.schema.js";
import type { ProjectConfig } from "../types/config.schema.js";
import type { Container } from "../container.js";

function printInitHelp() {
  ui.header();
  ui.break();
  ui.line("Usage: swiftcn init [options]");
  ui.break();
  ui.line("Initialize swiftcn in your project. Creates a swiftcn.json config");
  ui.line("file, installs theme files, and optionally sets up SDUI.");
  ui.break();

  ui.section("Options");
  ui.break();
  ui.command("-p, --path <path>      ", "Path to components directory (default: Components)");
  ui.command("--theme-path <path>    ", "Path to theme directory (default: Theme)");
  ui.command("--sdui                 ", "Include SDUI infrastructure");
  ui.command("--sdui-path <path>     ", "Path to SDUI directory (default: SDUI)");
  ui.command("-y, --yes              ", "Skip prompts and use defaults");
  ui.command("-h, --help             ", "Show help for init command");
  ui.break();

  ui.section("Examples");
  ui.break();
  ui.command("swiftcn init                       ", "Initialize with interactive prompts");
  ui.command("swiftcn init -y                    ", "Initialize with all defaults");
  ui.command("swiftcn init --sdui -y             ", "Initialize with SDUI, skip prompts");
  ui.command("swiftcn init -p App/Components     ", "Set custom components directory");
  ui.command("swiftcn init --theme-path App/Theme", "Set custom theme directory");
  ui.command("swiftcn init --sdui                ", "Include SDUI infrastructure");
  ui.command("swiftcn init --sdui-path App/SDUI  ", "Set custom SDUI directory (implies --sdui)");
  ui.command("swiftcn init -p App/Components --theme-path App/Theme --sdui-path App/SDUI", "Full custom paths");
  ui.break();

  ui.hint("Theme files are always installed. SDUI is opt-in via --sdui or --sdui-path.");
  ui.break();
  ui.end(`Run ${ui.accent("swiftcn add <component>")} after init to add components.`);
}

export function createInitCommand(container: Container): Command {
  const cmd = new Command()
    .name("init")
    .description("Initialize swiftcn in your project")
    .helpOption("-h, --help", "Show help for init command")
    .option("-p, --path <path>", "Path to components directory")
    .option("--theme-path <path>", "Path to theme directory")
    .option("--sdui", "Include SDUI infrastructure")
    .option("--sdui-path <path>", "Path to SDUI directory")
    .option("-y, --yes", "Skip prompts and use defaults")
    .action(async (rawOptions) => {
      const options = InitOptionsSchema.parse(rawOptions);
      const cwd = process.cwd();

      ui.header();

      // Step 1: Check existing config
      if (await container.config.exists(cwd)) {
        const shouldOverwrite = await p.confirm({
          message: "swiftcn.json already exists. Overwrite?",
          initialValue: false,
        });

        if (p.isCancel(shouldOverwrite) || !shouldOverwrite) {
          p.cancel("Initialization cancelled.");
          process.exit(0);
        }
      }

      // Step 2: Gather configuration (CLI flags or interactive prompts)
      // Detect explicitly passed flags (undefined = not passed)
      const hasPath = !!rawOptions.path;
      const hasThemePath = !!rawOptions.themePath;
      const hasSduiPath = !!rawOptions.sduiPath;

      let componentsPath = options.path;
      let themePath = options.themePath;
      let withSdui = options.sdui ?? hasSduiPath;
      let sduiPath = options.sduiPath;

      if (!options.yes) {
        const answers = await p.group(
          {
            componentsPath: () =>
              hasPath
                ? Promise.resolve(componentsPath)
                : p.text({
                    message: "Where would you like to store components?",
                    initialValue: componentsPath,
                    validate: (value) => {
                      if (!value) return "Path is required";
                    },
                  }),

            themePath: () =>
              hasThemePath
                ? Promise.resolve(themePath)
                : p.text({
                    message: "Where would you like to store theme files?",
                    initialValue: themePath,
                    validate: (value) => {
                      if (!value) return "Path is required";
                    },
                  }),

            withSdui: () =>
              withSdui
                ? Promise.resolve(true)
                : p.confirm({
                    message: "Include SDUI infrastructure?",
                    initialValue: false,
                  }),

            sduiPath: ({ results }) =>
              results.withSdui && !hasSduiPath
                ? p.text({
                    message: "Where would you like to store SDUI files?",
                    initialValue: sduiPath,
                    validate: (value) => {
                      if (!value) return "Path is required";
                    },
                  })
                : Promise.resolve(sduiPath),
          },
          {
            onCancel: () => {
              p.cancel("Initialization cancelled.");
              process.exit(0);
            },
          }
        );

        componentsPath = answers.componentsPath as string;
        themePath = answers.themePath as string;
        withSdui = answers.withSdui as boolean;
        sduiPath = (answers.sduiPath as string | undefined) ?? sduiPath;
      }

      // Step 3: Create directories and install files
      ui.break();
      ui.step("Creating project structure...");
      ui.break();

      try {
        const fullComponentsPath = path.join(cwd, componentsPath);
        await container.file.ensureDir(fullComponentsPath);

        const fullThemePath = path.join(cwd, themePath);
        await container.file.ensureDir(fullThemePath);

        ui.step("Installing theme files...");
        ui.break();

        const themeResult = await container.fetcher.fetchTheme(fullThemePath, {
          force: true,
        });

        for (const file of themeResult.added) {
          ui.fileAdded(path.relative(cwd, file));
        }

        ui.break();

        if (withSdui) {
          const fullSduiPath = path.join(cwd, sduiPath);
          await container.file.ensureDir(fullSduiPath);

          ui.step("Installing SDUI files...");
          ui.break();

          const sduiResult = await container.fetcher.fetchSdui(fullSduiPath, {
            force: true,
          });

          for (const file of sduiResult.added) {
            ui.fileAdded(path.relative(cwd, file));
          }

          ui.break();
        }

        // Step 4: Write config file
        const config: ProjectConfig = {
          componentsPath,
          themePath,
          sduiPath: withSdui ? sduiPath : undefined,
          prefix: "CN",
        };

        ui.step("Installing Swiftcn Config...");
        await container.config.write(config, cwd);
        ui.break();
        ui.fileAdded("swiftcn.json");

        // Step 5: Success message and next steps
        ui.break();
        ui.success("Project initialized!");
        ui.break();
        ui.section("Next steps");
        ui.break();
        ui.command("swiftcn add button", "Add your first component");
        ui.command("swiftcn list      ", "Browse all components");
        ui.break();
        ui.hint("Components are copied to your project — you own the code!");
        ui.break();
        ui.end("Happy coding!");
      } catch (error) {
        ui.error("Failed to initialize project");
        ui.line(error instanceof Error ? error.message : String(error));
        ui.end();
        process.exit(1);
      }
    });

  cmd.configureOutput({
    writeOut: () => {
      printInitHelp();
    },
  });

  return cmd;
}
