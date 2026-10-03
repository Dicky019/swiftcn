import { z } from "zod";
import { ArchitecturePresetSchema } from "./options.schema.js";

export const projectConfigSchema = z.object({
  componentsPath: z.string(),
  tokensPath: z.string().optional(),
  themePath: z.string().optional(),
  sduiPath: z.string().optional(),
  prefix: z.string().default("CN"),
  preset: ArchitecturePresetSchema.default("native"),
  navigation: z.boolean().default(false),
  offlineFirst: z.boolean().default(false),
});

export type ProjectConfig = z.infer<typeof projectConfigSchema>;
