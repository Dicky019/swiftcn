import fs from "fs-extra";
import path from "node:path";
import { type ZodType, type ZodTypeDef } from "zod";

export type CopyResult = {
  status: 'added' | 'skipped' | 'error';
  path: string;
  error?: string;
};

export interface FileService {
  copy(source: string, dest: string, options?: { force?: boolean }): Promise<CopyResult>;
  exists(filePath: string): Promise<boolean>;
  readJson<T>(filePath: string, schema: ZodType<T, ZodTypeDef, unknown>): Promise<T>;
  writeJson<T>(filePath: string, data: T): Promise<void>;
  ensureDir(dirPath: string): Promise<void>;
  readFile(filePath: string): Promise<string>;
}

export class FileServiceImpl implements FileService {
  async copy(source: string, dest: string, options?: { force?: boolean }): Promise<CopyResult> {
    try {
      // Check if source exists
      if (!await this.exists(source)) {
        return { status: 'error', path: dest, error: 'Sources file not found' };
      }

      // Check if destination exists
      if (await this.exists(dest) && !options?.force) {
        return { status: 'skipped', path: dest };
      }

      // Ensure destination directory exists
      await this.ensureDir(path.dirname(dest));

      // Copy file
      await fs.copy(source, dest);
      return { status: 'added', path: dest };
    } catch (error) {
      return {
        status: 'error',
        path: dest,
        error: error instanceof Error ? error.message : String(error)
      };
    }
  }

  async exists(filePath: string): Promise<boolean> {
    return fs.pathExists(filePath);
  }

  async readJson<T>(filePath: string, schema: ZodType<T, ZodTypeDef, unknown>): Promise<T> {
    const content = await fs.readFile(filePath, "utf-8");
    const data = JSON.parse(content);
    return schema.parse(data);
  }

  async writeJson<T>(filePath: string, data: T): Promise<void> {
    await fs.writeFile(filePath, JSON.stringify(data, null, 2) + "\n");
  }

  async ensureDir(dirPath: string): Promise<void> {
    await fs.ensureDir(dirPath);
  }

  async readFile(filePath: string): Promise<string> {
    return fs.readFile(filePath, "utf-8");
  }
}
