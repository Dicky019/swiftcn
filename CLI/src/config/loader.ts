import fs from "fs-extra";
import path from "path";
import { projectConfigSchema, CONFIG_FILE_NAME, type ProjectConfig } from "./types.js";

export async function loadConfig(cwd: string = process.cwd()): Promise<ProjectConfig | null> {
  const configPath = path.join(cwd, CONFIG_FILE_NAME);

  if (!await fs.pathExists(configPath)) {
    return null;
  }

  const content = await fs.readFile(configPath, "utf-8");
  const data = JSON.parse(content);
  return projectConfigSchema.parse(data);
}

export async function writeConfig(config: ProjectConfig, cwd: string = process.cwd()): Promise<void> {
  const configPath = path.join(cwd, CONFIG_FILE_NAME);
  await fs.writeFile(configPath, JSON.stringify(config, null, 2) + "\n");
}

export async function configExists(cwd: string = process.cwd()): Promise<boolean> {
  const configPath = path.join(cwd, CONFIG_FILE_NAME);
  return fs.pathExists(configPath);
}
