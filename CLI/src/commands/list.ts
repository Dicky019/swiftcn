import { Command } from "commander";
import pc from "picocolors";
import { ui } from "../utils/ui.js";
import { listComponents } from "../registry/loader.js";

export const listCommand = new Command()
  .name("list")
  .description("List available components")
  .option("-v, --verbose", "Show detailed information")
  .action(async (options) => {
    ui.header();

    try {
      const components = await listComponents();

      ui.section("Components");
      ui.break();

      if (options.verbose) {
        // Verbose mode - detailed info per component
        for (const component of components) {
          console.log(`${pc.gray("├")}  ${pc.bold(component.id)}`);
          console.log(`${pc.gray("│")}  ${pc.cyan(component.name)} ${pc.dim("·")} ${component.description}`);

          if (component.variants) {
            console.log(`${pc.gray("│")}  Variants: ${component.variants.join(` ${pc.dim("·")} `)}`);
          }

          if (component.sizes) {
            console.log(`${pc.gray("│")}  Sizes: ${component.sizes.join(` ${pc.dim("·")} `)}`);
          }

          if (component.sduiType) {
            console.log(`${pc.gray("│")}  SDUI: ${component.sduiType}`);
          }

          ui.break();
        }

        ui.section("");
        ui.break();
        ui.line("Usage");
        ui.info("  swiftcn add button           Add CNButton");
        ui.info("  swiftcn add button --sdui    Include SDUI extension");
        ui.info("  swiftcn add button --theme   Include theme files");
        ui.break();
        ui.end(`${components.length} components available`);
      } else {
        // Compact mode - table format
        const maxIdLen = Math.max(...components.map((c) => c.id.length));
        const maxNameLen = Math.max(...components.map((c) => c.name.length));

        for (const component of components) {
          const id = component.id.padEnd(maxIdLen);
          const name = component.name.padEnd(maxNameLen);
          const desc = component.description.length > 35
            ? component.description.slice(0, 35) + "..."
            : component.description;

          ui.line(`${pc.cyan(id)}  ${pc.bold(name)}  ${pc.dim(desc)}`);
        }

        ui.break();
        ui.info("All components are SDUI-compatible.");
        ui.break();
        ui.end(`Run ${pc.cyan("swiftcn add <name>")} to install a component.`);
      }
    } catch (error) {
      ui.error("Failed to load registry");
      ui.line(error instanceof Error ? error.message : String(error));
      ui.end();
      process.exit(1);
    }
  });
