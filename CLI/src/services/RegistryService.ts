import path from "node:path";
import { fileURLToPath } from "node:url";
import type { FileService } from "./FileService.js";
import {
  registrySchema,
  type Registry,
  type Component,
  type ComponentWithId,
} from "../types/registry.schema.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export interface RegistryService {
  load(): Promise<Registry>;
  getComponent(name: string): Promise<Component | null>;
  listComponents(): Promise<ComponentWithId[]>;
  getThemeFiles(): Promise<string[]>;
  getSduiFiles(): Promise<string[]>;
}

export class RegistryServiceImpl implements RegistryService {
  private cache: Registry | null = null;

  constructor(private file: FileService) {}

  async load(): Promise<Registry> {
    if (this.cache) return this.cache;

    const registryPath = path.resolve(__dirname, "../../registry.json");
    this.cache = await this.file.readJson(registryPath, registrySchema);
    return this.cache;
  }

  async getComponent(name: string): Promise<Component | null> {
    const registry = await this.load();
    return registry.components[name.toLowerCase()] ?? null;
  }

  async listComponents(): Promise<ComponentWithId[]> {
    const registry = await this.load();
    return Object.entries(registry.components).map(([id, component]) => ({
      id,
      ...component,
    }));
  }

  async getThemeFiles(): Promise<string[]> {
    const registry = await this.load();
    return [
      ...registry.theme.core,
      ...registry.theme.palettes,
      ...registry.theme.provider,
    ];
  }

  async getSduiFiles(): Promise<string[]> {
    const registry = await this.load();
    return [...registry.sdui.core, ...registry.sdui.wrappers];
  }
}
