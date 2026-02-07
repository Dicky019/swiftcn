import { Command } from "commander";
import * as p from "@clack/prompts";
import path from "node:path";
import { ui } from "../utils/ui.js";
import { InitOptionsSchema } from "../types/options.schema.js";
import type { ProjectConfig } from "../types/config.schema.js";
import type { Container } from "../container.js";

export function createInitCommand(container: Container): Command {
  return new Command()
    .name("init")
    .description("Initialize swiftcn in your project")
    .option("-p, --path <path>", "Path to components directory", "Components")
    .option("--theme", "Include theme provider")
    .option("--theme-path <path>", "Path to theme directory", "Theme")
    .option("--sdui", "Include SDUI infrastructure")
    .option("--sdui-path <path>", "Path to SDUI directory", "SDUI")
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
      let componentsPath = options.path;
      let withTheme = options.theme ?? false;
      let themePath = options.themePath;
      let withSdui = options.sdui ?? false;
      let sduiPath = options.sduiPath;

      if (!options.yes) {
        const answers = await p.group(
          {
            componentsPath: () =>
              p.text({
                message: "Where would you like to store components?",
                initialValue: componentsPath,
                validate: (value) => {
                  if (!value) return "Path is required";
                },
              }),

            withTheme: () =>
              p.confirm({
                message: "Include theme provider?",
                initialValue: true,
              }),

            themePath: ({ results }) =>
              results.withTheme
                ? p.text({
                    message: "Where would you like to store theme files?",
                    initialValue: themePath,
                    validate: (value) => {
                      if (!value) return "Path is required";
                    },
                  })
                : Promise.resolve(themePath),

            withSdui: () =>
              p.confirm({
                message: "Include SDUI infrastructure?",
                initialValue: false,
              }),

            sduiPath: ({ results }) =>
              results.withSdui
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
        withTheme = answers.withTheme as boolean;
        themePath = (answers.themePath as string | undefined) ?? themePath;
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

        if (withTheme) {
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
        }

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
          themePath: withTheme ? themePath : undefined,
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
}
