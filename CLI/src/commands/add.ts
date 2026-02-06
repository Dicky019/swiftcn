import { Command } from "commander";
import path from "node:path";
import { ui } from "../utils/ui.js";
import { AddOptionsSchema } from "../types/options.schema.js";
import type { Container } from "../container.js";

export function createAddCommand(container: Container): Command {
  return new Command()
    .name("add")
    .description("Add a component to your project")
    .argument("<component>", "The component to add (e.g., button, card, input)")
    .option("-f, --force", "Overwrite existing files")
    .option("--sdui", "Also copy SDUI extension file")
    .option("--theme", "Also copy required theme files")
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

        if (options.sdui && component.sdui_files) {
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

        let totalFiles = result.added.length;

        // Step 4: Fetch theme files (optional)
        if (options.theme && config.themePath) {
          ui.break();
          ui.step("Installing theme...");
          ui.break();

          const themeDir = path.join(cwd, config.themePath);
          const themeResult = await container.fetcher.fetchTheme(themeDir, {
            force: options.force,
          });

          for (const file of themeResult.added) {
            ui.fileAdded(path.relative(cwd, file));
          }

          for (const file of themeResult.skipped) {
            ui.fileExists(path.relative(cwd, file));
          }

          totalFiles += themeResult.added.length;
        }

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

        if (component.sduiType && !options.sdui) {
          ui.break();
          ui.hint(
            `Use ${ui.accent("--sdui")} to include SDUI Configuration struct.`
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
}
