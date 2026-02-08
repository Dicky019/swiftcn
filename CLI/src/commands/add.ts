import { Command } from "commander";
import path from "node:path";
import { ui } from "../utils/ui.js";
import { AddOptionsSchema } from "../types/options.schema.js";
import type { Container } from "../container.js";

function printAddHelp() {
  ui.header();
  ui.break();
  ui.line("Usage: swiftcn add <component> [options]");
  ui.break();
  ui.line("Add a component to your project. Copies the component source");
  ui.line("files into your configured directory.");
  ui.break();

  ui.section("Arguments");
  ui.break();
  ui.command("component              ", "The component to add (e.g., button, card, input)");
  ui.break();

  ui.section("Options");
  ui.break();
  ui.command("-f, --force            ", "Overwrite existing files");
  ui.command("--no-sdui              ", "Skip SDUI extension file");
  ui.command("-h, --help             ", "Show help for add command");
  ui.break();

  ui.section("Examples");
  ui.break();
  ui.command("swiftcn add button          ", "Add CNButton component");
  ui.command("swiftcn add card            ", "Add CNCard component");
  ui.command("swiftcn add button -f       ", "Overwrite existing files");
  ui.command("swiftcn add button --no-sdui", "Skip SDUI extension file");
  ui.command("swiftcn add button -f --no-sdui", "Force without SDUI");
  ui.break();

  ui.hint("Run swiftcn init first to set up your project.");
  ui.break();
  ui.end(`Run ${ui.accent("swiftcn list")} to see all available components.`);
}

export function createAddCommand(container: Container): Command {
  const cmd = new Command()
    .name("add")
    .description("Add a component to your project")
    .helpOption("-h, --help", "Show help for add command")
    .argument("<component>", "The component to add (e.g., button, card, input)")
    .option("-f, --force", "Overwrite existing files")
    .option("--no-sdui", "Skip SDUI extension file")
    .action(async (componentName: string, rawOptions) => {
      const options = AddOptionsSchema.parse(rawOptions);
      const cwd = process.cwd();

      ui.header();

      // Step 1: Load config
      const config = await container.config.load(cwd);
      if (!config) {
        ui.break();
        ui.error("No swiftcn.json found.");
        ui.break();
        ui.end(`Run ${ui.accent("swiftcn init")} to set up your project.`);
        process.exit(1);
      }

      // Step 2: Find component in registry
      const component = await container.registry.getComponent(componentName);
      if (!component) {
        ui.break();
        ui.error(`Component "${componentName}" not found.`);
        ui.break();

        const components = await container.registry.listComponents();
        const maxIdLen = Math.max(...components.map((c) => c.id.length));

        ui.section("Available");
        ui.break();
        for (const c of components) {
          ui.command(c.id.padEnd(maxIdLen), c.name);
        }
        ui.break();
        ui.end(`Run ${ui.accent("swiftcn list")} for details.`);
        process.exit(1);
      }

      // Step 3: Fetch component files
      ui.break();
      ui.step(`Installing ${component.name}...`);
      ui.break();

      try {
        const destDir = path.join(cwd, config.componentsPath);
        const filesToFetch = [...component.files];

        if (config.sduiPath && component.sdui_files && options.sdui !== false) {
          filesToFetch.push(...component.sdui_files);
        }

        const result = await container.fetcher.fetchComponents(
          filesToFetch,
          destDir,
          { force: options.force }
        );

        for (const file of result.added) {
          ui.fileAdded(path.relative(cwd, file));
        }

        for (const file of result.skipped) {
          ui.fileExists(path.relative(cwd, file));
        }

        const totalFiles = result.added.length;

        if (result.skipped.length > 0 && result.added.length === 0) {
          ui.break();
          ui.hint(`Use ${ui.accent("--force")} to overwrite existing files.`);
        }

        // Step 5: Success message
        ui.break();
        ui.success("Done!");
        ui.break();
        ui.section(component.name);
        ui.break();

        if (component.variants) {
          ui.labeledList("Variants", component.variants);
        }

        if (component.sizes) {
          ui.labeledList("Sizes", component.sizes);
        }

        if (component.sduiType && !config.sduiPath) {
          ui.break();
          ui.hint(
            `Run ${ui.accent("swiftcn init --sdui")} to enable SDUI support.`
          );
        }

        ui.break();
        ui.end(`${totalFiles} file${totalFiles === 1 ? "" : "s"} added`);
      } catch (error) {
        ui.error("Failed to add component");
        ui.line(error instanceof Error ? error.message : String(error));
        ui.end();
        process.exit(1);
      }
    });

  cmd.configureOutput({
    writeOut: () => {
      printAddHelp();
    },
  });

  return cmd;
}
