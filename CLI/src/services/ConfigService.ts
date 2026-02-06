import path from "node:path";
import type { FileService } from "./FileService.js";
import {
  projectConfigSchema,
  type ProjectConfig,
} from "../types/config.schema.js";
import { CONFIG_FILE_NAME } from "../utils/constants.js";

export interface ConfigService {
  load(cwd?: string): Promise<ProjectConfig | null>;
  write(config: ProjectConfig, cwd?: string): Promise<void>;
  exists(cwd?: string): Promise<boolean>;
}

export class ConfigServiceImpl implements ConfigService {
  constructor(private file: FileService) {}

  private configPath(cwd: string): string {
    return path.join(cwd, CONFIG_FILE_NAME);
  }

  async load(cwd: string = process.cwd()): Promise<ProjectConfig | null> {
    const configPath = this.configPath(cwd);

    if (!(await this.file.exists(configPath))) {
      return null;
    }

    return this.file.readJson<ProjectConfig>(configPath, projectConfigSchema);
  }

  async write(
    config: ProjectConfig,
    cwd: string = process.cwd()
  ): Promise<void> {
    const configPath = this.configPath(cwd);
    await this.file.writeJson(configPath, config);
  }

  async exists(cwd: string = process.cwd()): Promise<boolean> {
    return this.file.exists(this.configPath(cwd));
  }
}
