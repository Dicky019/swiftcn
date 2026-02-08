import { Command } from "commander";
import pc from "picocolors";
import { ui } from "../utils/ui.js";
import { ListOptionsSchema } from "../types/options.schema.js";
import type { Container } from "../container.js";

function printListHelp() {
  ui.header();
  ui.break();
  ui.line("Usage: swiftcn list [options]");
  ui.break();
  ui.line("List all available components from the registry.");
  ui.line("Shows component names, descriptions, and SDUI support.");
  ui.break();

  ui.section("Options");
  ui.break();
  ui.command("-v, --verbose          ", "Show detailed component information");
  ui.command("-h, --help             ", "Show help for list command");
  ui.break();

  ui.section("Examples");
  ui.break();
  ui.command("swiftcn list           ", "List all components");
  ui.command("swiftcn list -v        ", "Show variants, sizes, and SDUI info");
  ui.command("swiftcn list --verbose ", "Same as -v");
  ui.break();

  ui.end(`Run ${ui.accent("swiftcn add <name>")} to install a component.`);
}

export function createListCommand(container: Container): Command {
  const cmd = new Command()
    .name("list")
    .description("List available components")
    .helpOption("-h, --help", "Show help for list command")
    .option("-v, --verbose", "Show detailed information")
    .action(async (rawOptions) => {
      const options = ListOptionsSchema.parse(rawOptions);
      ui.header();

      try {
        const components = await container.registry.listComponents();

        ui.break();
        ui.section("Components");
        ui.break();

        const maxIdLen = Math.max(...components.map((c) => c.id.length));
        const maxNameLen = Math.max(...components.map((c) => c.name.length));

        if (options.verbose) {
          for (const component of components) {
            const id = component.id.padEnd(maxIdLen);
            const name = component.name.padEnd(maxNameLen);

            ui.command(`${id}  ${name}`, component.description);

            if (component.variants) {
              ui.info(
                `   Variants: ${component.variants.join(` ${pc.dim("·")} `)}`
              );
            }

            if (component.sizes) {
              ui.info(
                `   Sizes: ${component.sizes.join(` ${pc.dim("·")} `)}`
              );
            }

            if (component.sduiType) {
              ui.info(`   SDUI: ${component.sduiType}`);
            }

            ui.break();
          }

          ui.section("Usage");
          ui.break();
          ui.command("swiftcn add button          ", "Add CNButton");
          ui.command("swiftcn add button -f       ", "Overwrite existing files");
          ui.command("swiftcn add button --no-sdui", "Skip SDUI extension");
          ui.break();
          ui.end(`${components.length} components available`);
        } else {
          for (const component of components) {
            const id = component.id.padEnd(maxIdLen);
            const name = component.name.padEnd(maxNameLen);
            const desc =
              component.description.length > 35
                ? component.description.slice(0, 35) + "..."
                : component.description;

            ui.line(
              `→ ${ui.accent(id)}  ${pc.bold(name)}  ${pc.dim(desc)}`
            );
          }

          ui.break();
          ui.hint("All components are SDUI-compatible.");
          ui.break();
          ui.end(
            `Run ${ui.accent("swiftcn add <name>")} to install a component.`
          );
        }
      } catch (error) {
        ui.error("Failed to load registry");
        ui.line(error instanceof Error ? error.message : String(error));
        ui.end();
        process.exit(1);
      }
    });

  cmd.configureOutput({
    writeOut: () => {
      printListHelp();
    },
  });

  return cmd;
}
