import { Command } from "commander";
import path from "path";
import pc from "picocolors";
import { ui } from "../utils/ui.js";
import { loadConfig } from "../config/loader.js";
import { getComponent, listComponents } from "../registry/loader.js";
import { fetchComponentFiles, fetchThemeFiles, type FetchResult } from "../utils/fetcher.js";

export const addCommand = new Command()
  .name("add")
  .description("Add a component to your project")
  .argument("<component>", "The component to add (e.g., button, card, input)")
  .option("-f, --force", "Overwrite existing files")
  .option("--sdui", "Also copy SDUI extension file")
  .option("--theme", "Also copy required theme files")
  .action(async (componentName: string, options) => {
    const cwd = process.cwd();

    ui.header();

    // Load config
    const config = await loadConfig(cwd);
    if (!config) {
      ui.error("No swiftcn.json found.");
      ui.break();
      ui.end(`Run ${pc.cyan("swiftcn init")} to set up your project.`);
      process.exit(1);
    }

    // Find component
    const component = await getComponent(componentName);
    if (!component) {
      ui.error(`Component "${componentName}" not found.`);
      ui.break();
      const components = await listComponents();
      const names = components.map((c) => c.id).join(` ${pc.dim("·")} `);
      ui.line("Available components:");
      ui.info(`  ${names}`);
      ui.break();
      ui.end(`Run ${pc.cyan("swiftcn list")} for details.`);
      process.exit(1);
    }

    ui.step(`Installing ${component.name}...`);
    ui.break();

    try {
      const destDir = path.join(cwd, config.componentsPath);
      const filesToFetch = [...component.files];

      // Add SDUI files if requested
      if (options.sdui && component.sdui_files) {
        filesToFetch.push(...component.sdui_files);
      }

      const result = await fetchComponentFiles(filesToFetch, destDir, {
        force: options.force,
      });

      // Print added files
      for (const file of result.added) {
        ui.fileAdded(path.relative(cwd, file));
      }

      // Print skipped files
      for (const file of result.skipped) {
        ui.fileExists(path.relative(cwd, file));
      }

      let totalFiles = result.added.length;

      // Copy theme files if requested
      if (options.theme && config.themePath) {
        ui.break();
        ui.step("Installing theme...");
        ui.break();

        const themeDir = path.join(cwd, config.themePath);
        const themeResult = await fetchThemeFiles(themeDir, { force: options.force });

        for (const file of themeResult.added) {
          ui.fileAdded(path.relative(cwd, file));
        }

        for (const file of themeResult.skipped) {
          ui.fileExists(path.relative(cwd, file));
        }

        totalFiles += themeResult.added.length;
      }

      // Show message if files were skipped
      if (result.skipped.length > 0 && result.added.length === 0) {
        ui.break();
        ui.info(`Use ${pc.cyan("--force")} to overwrite existing files.`);
      }

      ui.break();
      ui.step("Done!");
      ui.break();

      // Component info
      ui.section(component.name);

      if (component.variants) {
        ui.line(`Variants: ${component.variants.join(` ${pc.dim("·")} `)}`);
      }

      if (component.sizes) {
        ui.line(`Sizes: ${component.sizes.join(` ${pc.dim("·")} `)}`);
      }

      // Show SDUI tip if not included
      if (component.sduiType && !options.sdui) {
        ui.break();
        ui.info(`Tip: Use ${pc.cyan("--sdui")} to include SDUI Configuration struct.`);
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
