#!/usr/bin/env node

import { Command } from "commander";
import { createContainer } from "./container.js";
import { createInitCommand } from "./commands/init.js";
import { createAddCommand } from "./commands/add.js";
import { createListCommand } from "./commands/list.js";
import { ui } from "./utils/ui.js";

const VERSION = "1.0.0";

const container = createContainer();

const program = new Command();

program
  .name("swiftcn")
  .description("A CLI for adding shadcn-style SwiftUI components to your project.")
  .version(VERSION, "-v, --version", "Show version")
  .helpOption(false)
  .option("-h, --help", "Show help")
  .action((options) => {
    if (options.help) {
      printHelp();
    } else {
      printHelp();
    }
  });

function printHelp() {
  ui.header();
  ui.break();
  ui.line("Usage: swiftcn [options] [command]");
  ui.break();
  ui.line("A CLI for adding shadcn-style SwiftUI components to your project.");
  ui.break();

  ui.section("Options");
  ui.break();
  ui.command("-v, --version", "Show version");
  ui.command("-h, --help   ", "Show help");
  ui.break();

  ui.section("Commands");
  ui.break();
  ui.command("init [options]            ", "Initialize swiftcn in your project");
  ui.command("add [options] <component> ", "Add a component to your project");
  ui.command("list [options]            ", "List available components");
  ui.break();

  ui.section("Examples");
  ui.break();
  ui.command("swiftcn init             ", "Initialize swiftcn in your project");
  ui.command("swiftcn add button       ", "Add a single component");
  ui.command("swiftcn add button --sdui", "Add component with SDUI extension");
  ui.command("swiftcn list --verbose   ", "List all components with details");
  ui.break();

  ui.hint("Components are copied to your project — you own the code!");
  ui.break();
  ui.end(`Run ${ui.accent("swiftcn <command> --help")} for more info.`);
}

program.addCommand(createInitCommand(container));
program.addCommand(createAddCommand(container));
program.addCommand(createListCommand(container));

program.parse();
