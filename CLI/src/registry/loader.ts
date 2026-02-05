import fs from "fs-extra";
import path from "path";
import { fileURLToPath } from "url";
import { registrySchema, type Registry } from "./types.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export async function loadRegistry(): Promise<Registry> {
  const registryPath = path.resolve(__dirname, "../../registry.json");
  const content = await fs.readFile(registryPath, "utf-8");
  const data = JSON.parse(content);
  return registrySchema.parse(data);
}

export async function getComponent(name: string) {
  const registry = await loadRegistry();
  const component = registry.components[name.toLowerCase()];
  if (!component) {
    return null;
  }
  return component;
}

export async function listComponents() {
  const registry = await loadRegistry();
  return Object.entries(registry.components).map(([key, value]) => ({
    id: key,
    ...value,
  }));
}
