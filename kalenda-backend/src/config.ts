import "dotenv/config";
import { z } from "zod";

const schema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  PORT: z.coerce.number().int().positive().default(4000),
  DATABASE_URL: z.string().min(1).optional(),
  JWT_SECRET: z.string().min(8).default("alliya-kalenda-dev-secret-change-me"),
  JWT_ACCESS_TTL: z.string().min(1).default("15m"),
  JWT_REFRESH_TTL: z.string().min(1).default("7d"),
  CORS_ORIGIN: z.string().min(1).default("http://localhost:3000"),
});

export const config = schema.parse(process.env);

/** Origines CORS sous forme de liste. */
export const corsOrigins = config.CORS_ORIGIN.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

export const isProduction = config.NODE_ENV === "production";
