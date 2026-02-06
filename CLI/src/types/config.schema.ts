import { z } from "zod";

export const projectConfigSchema = z.object({
  componentsPath: z.string(),
  tokensPath: z.string().optional(),
  themePath: z.string().optional(),
  sduiPath: z.string().optional(),
  prefix: z.string().default("CN"),
});

export type ProjectConfig = z.infer<typeof projectConfigSchema>;
