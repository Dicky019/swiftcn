import path from "node:path";
import type { GitService } from "./GitService.js";
import type { FileService, CopyResult } from "./FileService.js";
import type { RegistryService } from "./RegistryService.js";
import { ALLOWED_REPO_URLS, SOURCE_PATH } from "../utils/constants.js";

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
      await this.git.clone(repoUrl, tempDir);

      for (const file of files) {
        const sourcePath = path.join(tempDir, SOURCE_PATH, file);

        // Determine destination: strip prefix if provided, otherwise use basename
        const relativePath = options.stripPrefix
          ? file.replace(new RegExp(`^${options.stripPrefix}`), "")
          : path.basename(file);

        const destPath = path.join(destDir, relativePath);

        const copyResult: CopyResult = await this.file.copy(
          sourcePath,
          destPath,
          { force: options.force }
        );

        if (copyResult.status === "added") {
          result.added.push(destPath);
        } else if (copyResult.status === "skipped") {
          result.skipped.push(destPath);
        }
      }

      return result;
    } finally {
      await this.git.cleanup(tempDir);
    }
  }
}
