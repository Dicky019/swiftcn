import fs from "fs-extra";
import path from "path";
import { simpleGit } from "simple-git";
import os from "os";

const REPO_URL = "https://github.com/Dicky019/swiftcn.git";
const SOURCE_PATH = "Source";

export interface FetchResult {
  added: string[];
  skipped: string[];
}

export async function fetchComponentFiles(
  files: string[],
  destDir: string,
  options: { force?: boolean } = {}
): Promise<FetchResult> {
  const tempDir = path.join(os.tmpdir(), `swiftcn-${Date.now()}`);
  const git = simpleGit();
  const result: FetchResult = { added: [], skipped: [] };

  try {
    // Clone the repo with depth 1
    await git.clone(REPO_URL, tempDir, ["--depth=1", "--single-branch"]);

    for (const file of files) {
      const sourcePath = path.join(tempDir, SOURCE_PATH, file);
      const destPath = path.join(destDir, path.basename(file));

      // Check if file exists in repo
      if (!await fs.pathExists(sourcePath)) {
        continue;
      }

      // Check if destination exists
      if (await fs.pathExists(destPath) && !options.force) {
        result.skipped.push(destPath);
        continue;
      }

      // Ensure destination directory exists
      await fs.ensureDir(path.dirname(destPath));

      // Copy file
      await fs.copy(sourcePath, destPath);
      result.added.push(destPath);
    }

    return result;
  } finally {
    // Cleanup temp directory
    await fs.remove(tempDir).catch(() => {});
  }
}

export async function fetchThemeFiles(
  destDir: string,
  options: { force?: boolean } = {}
): Promise<FetchResult> {
  const tempDir = path.join(os.tmpdir(), `swiftcn-theme-${Date.now()}`);
  const git = simpleGit();
  const result: FetchResult = { added: [], skipped: [] };

  const themeFiles = [
    "Theme/Core/Theme.swift",
    "Theme/Core/ThemeTokens.swift",
    "Theme/Core/Color+Hex.swift",
    "Theme/Palettes/ThemeDefaults.swift",
    "Theme/Provider/ThemeProvider.swift",
    "Theme/Provider/ThemeEnvironment.swift",
    "Theme/Provider/ResolvedTheme.swift",
  ];

  try {
    // Clone the repo with depth 1
    await git.clone(REPO_URL, tempDir, ["--depth=1", "--single-branch"]);

    for (const file of themeFiles) {
      const sourcePath = path.join(tempDir, SOURCE_PATH, file);
      // Preserve directory structure under Theme/
      const relativePath = file.replace(/^Theme\//, "");
      const destPath = path.join(destDir, relativePath);

      // Check if file exists in repo
      if (!await fs.pathExists(sourcePath)) {
        continue;
      }

      // Check if destination exists
      if (await fs.pathExists(destPath) && !options.force) {
        result.skipped.push(destPath);
        continue;
      }

      // Ensure destination directory exists
      await fs.ensureDir(path.dirname(destPath));

      // Copy file
      await fs.copy(sourcePath, destPath);
      result.added.push(destPath);
    }

    return result;
  } finally {
    // Cleanup temp directory
    await fs.remove(tempDir).catch(() => {});
  }
}

export async function fetchSduiFiles(
  destDir: string,
  options: { force?: boolean } = {}
): Promise<FetchResult> {
  const tempDir = path.join(os.tmpdir(), `swiftcn-sdui-${Date.now()}`);
  const git = simpleGit();
  const result: FetchResult = { added: [], skipped: [] };

  const sduiFiles = [
    "SDUI/Core/AnyCodable.swift",
    "SDUI/Core/SDUINode.swift",
    "SDUI/Core/SDUIError.swift",
    "SDUI/Rendering/SDUIRenderer.swift",
    "SDUI/Rendering/SDUIRegistry.swift",
    "SDUI/Actions/SDUIActionHandler.swift",
    "SDUI/Wrappers/SDUIInputWrapper.swift",
    "SDUI/Wrappers/SDUISwitchWrapper.swift",
    "SDUI/Wrappers/SDUISliderWrapper.swift",
  ];

  try {
    // Clone the repo with depth 1
    await git.clone(REPO_URL, tempDir, ["--depth=1", "--single-branch"]);

    for (const file of sduiFiles) {
      const sourcePath = path.join(tempDir, SOURCE_PATH, file);
      // Preserve directory structure under SDUI/
      const relativePath = file.replace(/^SDUI\//, "");
      const destPath = path.join(destDir, relativePath);

      // Check if file exists in repo
      if (!await fs.pathExists(sourcePath)) {
        continue;
      }

      // Check if destination exists
      if (await fs.pathExists(destPath) && !options.force) {
        result.skipped.push(destPath);
        continue;
      }

      // Ensure destination directory exists
      await fs.ensureDir(path.dirname(destPath));

      // Copy file
      await fs.copy(sourcePath, destPath);
      result.added.push(destPath);
    }

    return result;
  } finally {
    // Cleanup temp directory
    await fs.remove(tempDir).catch(() => {});
  }
}
