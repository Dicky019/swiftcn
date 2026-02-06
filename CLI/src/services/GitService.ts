import { simpleGit } from "simple-git";
import fs from "fs-extra";
import path from "node:path";
import os from "node:os";
import { ALLOWED_REPO_URLS } from "../utils/constants.js";

export interface GitService {
  clone(repoUrl: string, targetDir: string): Promise<void>;
  cleanup(tempDir: string): Promise<void>;
  createTempDir(prefix: string): string;
}

export class GitServiceImpl implements GitService {
  async clone(repoUrl: string, targetDir: string): Promise<void> {
    if (!ALLOWED_REPO_URLS.includes(repoUrl as typeof ALLOWED_REPO_URLS[number])) {
      throw new Error(`Untrusted repository URL: ${repoUrl}`);
    }

    const git = simpleGit();
    await git.clone(repoUrl, targetDir, ["--depth=1", "--single-branch"]);
  }

  async cleanup(tempDir: string): Promise<void> {
    await fs.remove(tempDir).catch(() => {});
  }

  createTempDir(prefix: string): string {
    return path.join(os.tmpdir(), `${prefix}-${Date.now()}`);
  }
}
