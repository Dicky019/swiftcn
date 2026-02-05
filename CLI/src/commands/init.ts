import { Command } from "commander";
import * as p from "@clack/prompts";
import fs from "fs-extra";
import path from "path";
import { ui } from "../utils/ui.js";
import { writeConfig, configExists } from "../config/loader.js";
import { fetchThemeFiles, fetchSduiFiles } from "../utils/fetcher.js";
import type { ProjectConfig } from "../config/types.js";

export const initCommand = new Command()
  .name("init")
  .description("Initialize swiftcn in your project")
  .option("-p, --path <path>", "Path to components directory", "Sources/Components")
  .option("--theme", "Include theme provider")
  .option("--sdui", "Include SDUI infrastructure")
  .option("-y, --yes", "Skip prompts and use defaults")
  .action(async (options) => {
    const cwd = process.cwd();

    ui.header();

    // Check if already initialized
    if (await configExists(cwd)) {
      const shouldOverwrite = await p.confirm({
        message: "swiftcn.json already exists. Overwrite?",
        initialValue: false,
      });

      if (p.isCancel(shouldOverwrite) || !shouldOverwrite) {
        p.cancel("Initialization cancelled.");
        process.exit(0);
      }
    }

    let componentsPath = options.path;
    let withTheme = options.theme ?? false;
    let withSdui = options.sdui ?? false;

    // Interactive prompts if not using --yes
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
          withSdui: () =>
            p.confirm({
              message: "Include SDUI infrastructure?",
              initialValue: false,
            }),
        },
        {
          onCancel: () => {
            p.cancel("Initialization cancelled.");
            process.exit(0);
          },
        }
      );

      componentsPath = answers.componentsPath;
      withTheme = answers.withTheme;
      withSdui = answers.withSdui;
    }

    ui.break();
    ui.step("Creating project structure...");
    ui.break();

    try {
      const files: string[] = [];

      // Create components directory
      const fullComponentsPath = path.join(cwd, componentsPath);
      await fs.ensureDir(fullComponentsPath);
      files.push(`${componentsPath}/`);

      // Create optional directories and fetch files
      if (withTheme) {
        const themePath = path.join(cwd, componentsPath, "Theme");
        await fs.ensureDir(themePath);

        ui.step("Installing theme files...");
        ui.break();

        const themeResult = await fetchThemeFiles(themePath, { force: true });

        for (const file of themeResult.added) {
          ui.fileAdded(path.relative(cwd, file));
        }

        files.push(...themeResult.added.map(f => path.relative(cwd, f)));
        ui.break();
      }

      if (withSdui) {
        const sduiPath = path.join(cwd, componentsPath, "SDUI");
        await fs.ensureDir(sduiPath);

        ui.step("Installing SDUI files...");
        ui.break();

        const sduiResult = await fetchSduiFiles(sduiPath, { force: true });

        for (const file of sduiResult.added) {
          ui.fileAdded(path.relative(cwd, file));
        }

        files.push(...sduiResult.added.map(f => path.relative(cwd, f)));
        ui.break();
      }

      // Write config
      const config: ProjectConfig = {
        componentsPath,
        themePath: withTheme ? `${componentsPath}/Theme` : undefined,
        sduiPath: withSdui ? `${componentsPath}/SDUI` : undefined,
        prefix: "CN",
      };

      await writeConfig(config, cwd);
      files.push("swiftcn.json");

      // Print created files
      files.forEach((file, index) => {
        ui.fileTree(file, index === files.length - 1);
      });

      console.log();
      ui.step("Project initialized!");
      ui.break();
      ui.section("Next steps");
      ui.break();
      ui.numberedStep(1, "Add a component", "swiftcn add button");
      ui.break();
      ui.numberedStep(2, "View all components", "swiftcn list");
      ui.break();
      ui.end("Happy coding!");
    } catch (error) {
      ui.error("Failed to initialize project");
      ui.line(error instanceof Error ? error.message : String(error));
      ui.end();
      process.exit(1);
    }
  });
