import { z } from "zod";

export const InitOptionsSchema = z.object({
  path: z.string().default("Sources/Components"),
  theme: z.boolean().optional(),
  themePath: z.string().default("Sources/Theme"),
  sdui: z.boolean().optional(),
  sduiPath: z.string().default("Sources/SDUI"),
  yes: z.boolean().optional(),
});

export const AddOptionsSchema = z.object({
  force: z.boolean().optional(),
  sdui: z.boolean().optional(),
  theme: z.boolean().optional(),
});

export const ListOptionsSchema = z.object({
  verbose: z.boolean().optional(),
});

export type InitOptions = z.infer<typeof InitOptionsSchema>;
export type AddOptions = z.infer<typeof AddOptionsSchema>;
export type ListOptions = z.infer<typeof ListOptionsSchema>;
