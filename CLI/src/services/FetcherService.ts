import path from "node:path";
import type { GitService } from "./GitService.js";
import type { FileService } from "./FileService.js";
import type { RegistryService } from "./RegistryService.js";
import {
  ALLOWED_REPO_URLS,
  SOURCE_PATH,
  SOURCE_REF,
} from "../utils/constants.js";
import { resolveSecurePath } from "../utils/paths.js";
import { ErrorCode, SwiftCNError } from "../utils/errors.js";

function destinationPath(file: string, stripPrefix: string | null): string {
  if (!stripPrefix) return path.basename(file);
  if (file.startsWith(stripPrefix)) return file.slice(stripPrefix.length);

  throw new SwiftCNError(
    `Registry path must start with ${stripPrefix}: ${file}`,
    ErrorCode.INVALID_INPUT
  );
}

export interface FetchOptions {
  force?: boolean;
}

export interface FetchResult {
  added: string[];
  skipped: string[];
}

export interface FetcherService {
  fetchComponents(
    files: string[],
    destDir: string,
    options?: FetchOptions
  ): Promise<FetchResult>;
  fetchTheme(destDir: string, options?: FetchOptions): Promise<FetchResult>;
  fetchSdui(destDir: string, options?: FetchOptions): Promise<FetchResult>;
}

export class FetcherServiceImpl implements FetcherService {
  constructor(
    private git: GitService,
    private file: FileService,
    private registry: RegistryService
  ) {}

  async fetchComponents(
    files: string[],
    destDir: string,
    options: FetchOptions = {}
  ): Promise<FetchResult> {
    return this.fetchFiles(files, destDir, {
      force: options.force,
      stripPrefix: null,
    });
  }

  async fetchTheme(
    destDir: string,
    options: FetchOptions = {}
  ): Promise<FetchResult> {
    const files = await this.registry.getThemeFiles();
    return this.fetchFiles(files, destDir, {
      force: options.force,
      stripPrefix: "Theme/",
    });
  }

  async fetchSdui(
    destDir: string,
    options: FetchOptions = {}
  ): Promise<FetchResult> {
    const files = await this.registry.getSduiFiles();
    return this.fetchFiles(files, destDir, {
      force: options.force,
      stripPrefix: "SDUI/",
    });
  }

  private async fetchFiles(
    files: string[],
    destDir: string,
    options: { force?: boolean; stripPrefix: string | null }
  ): Promise<FetchResult> {
    const repoUrl = ALLOWED_REPO_URLS[0];
    const tempDir = this.git.createTempDir("swiftcn");
    const result: FetchResult = { added: [], skipped: [] };

    try {
      await this.git.clone(repoUrl, tempDir, SOURCE_REF);

      const sourceRoot = path.join(tempDir, SOURCE_PATH);

      for (const file of files) {
        const sourcePath = resolveSecurePath(sourceRoot, file);
        const relativePath = destinationPath(file, options.stripPrefix);
        const destPath = resolveSecurePath(destDir, relativePath);
        const copyResult = await this.file.copy(sourcePath, destPath, {
          force: options.force,
        });

        if (copyResult.status === "error") {
          throw new SwiftCNError(
            copyResult.error ?? `Failed to copy ${file}`,
            ErrorCode.FILE_COPY_FAILED
          );
        }

        if (copyResult.status === "added") result.added.push(destPath);
        if (copyResult.status === "skipped") result.skipped.push(destPath);
      }

      return result;
    } finally {
      await this.git.cleanup(tempDir);
    }
  }
}
