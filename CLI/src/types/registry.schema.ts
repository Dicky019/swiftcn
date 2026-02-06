import { z } from "zod";

export const componentSchema = z.object({
  name: z.string(),
  description: z.string(),
  files: z.array(z.string()),
  sdui_files: z.array(z.string()).optional(),
  variants: z.array(z.string()).optional(),
  sizes: z.array(z.string()).optional(),
  sduiType: z.string().optional(),
  sduiProps: z.array(z.string()).optional(),
});

export const registrySchema = z.object({
  $schema: z.string().optional(),
  name: z.string(),
  version: z.string(),
  description: z.string(),
  license: z.string(),
  author: z.string(),
  repository: z.string(),
  config: z.object({
    componentsPath: z.string(),
    themePath: z.string(),
    sduiPath: z.string(),
    platforms: z.array(z.string()),
    prefix: z.string(),
  }),
  theme: z.object({
    core: z.array(z.string()),
    palettes: z.array(z.string()),
    provider: z.array(z.string()),
  }),
  components: z.record(z.string(), componentSchema),
  sdui: z.object({
    core: z.array(z.string()),
    wrappers: z.array(z.string()),
    transports: z.record(z.string(), z.string()),
  }),
});

export type Component = z.infer<typeof componentSchema>;
export type Registry = z.infer<typeof registrySchema>;

// Extended type with id
export type ComponentWithId = Component & { id: string };
