import path from "node:path";
import type { GitService } from "./GitService.js";
import type { FileService } from "./FileService.js";
import type { FileTransactionService, InitFileRequest, InitTransactionResult } from "./FileTransactionService.js";
import { projectConfigSchema, type ProjectConfig } from "../types/config.schema.js";
import { registrySchema } from "../types/registry.schema.js";
import { ALLOWED_REPO_URLS, SOURCE_PATH, SOURCE_REF } from "../utils/constants.js";
import { resolveSecurePath } from "../utils/paths.js";
import { ErrorCode, SwiftCNError } from "../utils/errors.js";

export interface InitializeProjectInput {
  cwd: string;
  config: ProjectConfig;
  includeSdui: boolean;
  includeNavigationRouter: boolean;
  includeOfflineFirst: boolean;
  force?: boolean;
}

export interface InitService {
  recover(cwd: string): Promise<void>;
  initialize(input: InitializeProjectInput): Promise<InitTransactionResult>;
}

export class InitServiceImpl implements InitService {
  constructor(
    private git: GitService,
    private file: FileService,
    private transaction: FileTransactionService
  ) {}

  async recover(cwd: string): Promise<void> {
    await this.transaction.recover(cwd);
  }

  async initialize(input: InitializeProjectInput): Promise<InitTransactionResult> {
    const config = projectConfigSchema.parse(input.config);
    // Recover before cloning; command callers also recover before loading config.
    await this.recover(input.cwd);
    const componentsPath = resolveSecurePath(input.cwd, config.componentsPath);
    const themePath = resolveSecurePath(input.cwd, config.themePath ?? "Theme");
    const sduiPath = input.includeSdui
      ? resolveSecurePath(input.cwd, config.sduiPath ?? "SDUI")
      : undefined;
    const foundationRoot = path.dirname(componentsPath);
    const navigationPath = resolveSecurePath(input.cwd, path.relative(input.cwd, path.join(foundationRoot, "Navigation")));
    const offlinePath = resolveSecurePath(input.cwd, path.relative(input.cwd, path.join(foundationRoot, "OfflineFirst")));
    const checkout = this.git.createTempDir("swiftcn-init");

    try {
      await this.git.clone(ALLOWED_REPO_URLS[0], checkout, SOURCE_REF);
      const registry = await this.file.readJson(path.join(checkout, "CLI/registry.json"), registrySchema);
      const sourceRoot = path.join(checkout, SOURCE_PATH);
      const files = [...registry.theme.core, ...registry.theme.palettes, ...registry.theme.provider]
        .map((source) => this.mapPrefixed(sourceRoot, source, "Theme/", themePath));

      if (sduiPath) {
        files.push(...[...registry.sdui.core, ...registry.sdui.wrappers]
          .map((source) => this.mapPrefixed(sourceRoot, source, "SDUI/", sduiPath)));
      }
      if (input.includeNavigationRouter && config.preset !== "tca") {
        const navigation = registry.components.navigation;
        if (!navigation || navigation.files.length !== 1 || navigation.files[0] !== "Navigation/Router.swift") {
          throw new SwiftCNError("Navigation registry must contain only Navigation/Router.swift", ErrorCode.REGISTRY_LOAD_FAILED);
        }
        files.push(this.mapPrefixed(sourceRoot, navigation.files[0], "Navigation/", navigationPath));
      }
      if (input.includeOfflineFirst) {
        if (!registry.offlineFirst) {
          throw new SwiftCNError(`Offline-First templates are unavailable in ${SOURCE_REF}; install a release containing Offline-First Core.`, ErrorCode.REGISTRY_LOAD_FAILED);
        }
        files.push(...registry.offlineFirst.core.map((source) => this.mapPrefixed(sourceRoot, source, "OfflineFirst/", offlinePath)));
      }
      for (const request of files) {
        if (!await this.file.exists(request.sourcePath)) {
          throw new SwiftCNError(`Missing source file: ${request.sourcePath}`, ErrorCode.FILE_COPY_FAILED);
        }
      }
      return await this.transaction.apply({ cwd: input.cwd, files, config, force: input.force });
    } finally {
      await this.git.cleanup(checkout);
    }
  }

  private mapPrefixed(sourceRoot: string, source: string, prefix: string, destinationRoot: string): InitFileRequest {
    if (!source.startsWith(prefix)) {
      throw new SwiftCNError(`Registry path must start with ${prefix}: ${source}`, ErrorCode.INVALID_INPUT);
    }
    return {
      sourcePath: resolveSecurePath(sourceRoot, source),
      destinationPath: resolveSecurePath(destinationRoot, source.slice(prefix.length)),
    };
  }
}
