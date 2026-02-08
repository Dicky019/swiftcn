import { vi } from "vitest";
import { Command } from "commander";
import type { Container } from "../../container.js";
import type { ConfigService } from "../../services/ConfigService.js";
import type { FileService } from "../../services/FileService.js";
import type {
  FetcherService,
  FetchResult,
} from "../../services/FetcherService.js";
import type { GitService } from "../../services/GitService.js";
import type { RegistryService } from "../../services/RegistryService.js";
import type { ComponentWithId } from "../../types/registry.schema.js";
import type { ProjectConfig } from "../../types/config.schema.js";

export const emptyFetchResult: FetchResult = { added: [], skipped: [] };

export const themeFetchResult: FetchResult = {
  added: ["/project/Theme/Core/Theme.swift"],
  skipped: [],
};

export const sduiFetchResult: FetchResult = {
  added: ["/project/SDUI/Core/SDUINode.swift"],
  skipped: [],
};

export const sampleConfig: ProjectConfig = {
  componentsPath: "Components",
  themePath: "Theme",
  prefix: "CN",
};

export const sampleConfigWithSdui: ProjectConfig = {
  ...sampleConfig,
  sduiPath: "SDUI",
};

export const sampleButton: ComponentWithId = {
  id: "button",
  name: "CNButton",
  description: "A customizable button with size and variant options",
  files: ["Components/CNButton.swift"],
  sdui_files: ["Components/CNButton+SDUI.swift"],
  variants: ["default", "destructive", "outline", "secondary", "ghost", "link"],
  sizes: ["sm", "md", "lg"],
  sduiType: "button",
  sduiProps: ["label", "variant", "size", "actionId"],
};

export const sampleCard: ComponentWithId = {
  id: "card",
  name: "CNCard",
  description: "A container with rounded corners and shadow",
  files: ["Components/CNCard.swift"],
  sdui_files: ["Components/CNCard+SDUI.swift"],
  variants: ["elevated", "outlined", "filled"],
  sduiType: "card",
  sduiProps: ["variant"],
};

export const sampleComponents: ComponentWithId[] = [sampleButton, sampleCard];

export function createMockContainer(
  overrides: Partial<Container> = {}
): Container {
  const config: ConfigService = {
    load: vi.fn().mockResolvedValue(null),
    write: vi.fn().mockResolvedValue(undefined),
    exists: vi.fn().mockResolvedValue(false),
  };

  const file: FileService = {
    copy: vi.fn(),
    exists: vi.fn().mockResolvedValue(false),
    readJson: vi.fn(),
    writeJson: vi.fn(),
    ensureDir: vi.fn(),
    readFile: vi.fn(),
  };

  const fetcher: FetcherService = {
    fetchComponents: vi.fn().mockResolvedValue(emptyFetchResult),
    fetchTheme: vi.fn().mockResolvedValue(themeFetchResult),
    fetchSdui: vi.fn().mockResolvedValue(sduiFetchResult),
  };

  const git: GitService = {
    clone: vi.fn(),
    cleanup: vi.fn(),
    createTempDir: vi.fn().mockReturnValue("/tmp/swiftcn"),
  };

  const registry: RegistryService = {
    load: vi.fn().mockResolvedValue({}),
    getComponent: vi.fn(),
    listComponents: vi.fn().mockResolvedValue([]),
    getThemeFiles: vi.fn().mockResolvedValue([]),
    getSduiFiles: vi.fn().mockResolvedValue([]),
  };

  return { git, file, registry, config, fetcher, ...overrides };
}

/**
 * Creates a parent program matching the real CLI setup
 * (enablePositionalOptions + helpOption(false)) for help tests.
 */
export function createProgram(subcommand: Command): Command {
  const program = new Command()
    .name("swiftcn")
    .helpOption(false)
    .enablePositionalOptions()
    .option("-h, --help", "Show help")
    .action(() => {});
  program.addCommand(subcommand);
  return program;
}
