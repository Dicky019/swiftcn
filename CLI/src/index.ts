#!/usr/bin/env node

import { Command } from "commander";
import pc from "picocolors";
import { initCommand } from "./commands/init.js";
import { addCommand } from "./commands/add.js";
import { listCommand } from "./commands/list.js";

const VERSION = "1.0.0";

const program = new Command();

program
  .name("swiftcn")
  .description("A CLI for adding shadcn-style SwiftUI components to your project.")
  .version(VERSION, "-v, --version", "Show version")
  .helpOption("-h, --help", "Show help")
  .addHelpText("beforeAll", `${pc.bold("swiftcn")} ${pc.dim(`v${VERSION}`)}\n`)
  .addHelpText("after", `
${pc.bold("Examples")}
  swiftcn init
  swiftcn add button
  swiftcn add button --sdui --theme
  swiftcn list --verbose
`);

program.addCommand(initCommand);
program.addCommand(addCommand);
program.addCommand(listCommand);

program.parse();
