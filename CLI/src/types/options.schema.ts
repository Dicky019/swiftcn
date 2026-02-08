import { z } from "zod";

export const InitOptionsSchema = z.object({
  path: z.string().default("Components"),
  themePath: z.string().default("Theme"),
  sdui: z.boolean().optional(),
  sduiPath: z.string().default("SDUI"),
  yes: z.boolean().optional(),
});

export const AddOptionsSchema = z.object({
  force: z.boolean().optional(),
  sdui: z.boolean().optional(),
});

export const ListOptionsSchema = z.object({
  verbose: z.boolean().optional(),
});

export type InitOptions = z.infer<typeof InitOptionsSchema>;
export type AddOptions = z.infer<typeof AddOptionsSchema>;
export type ListOptions = z.infer<typeof ListOptionsSchema>;
