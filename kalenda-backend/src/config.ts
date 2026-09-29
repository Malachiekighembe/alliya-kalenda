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
  /**
   * Client ID de la console Google Cloud (type « Application Web » pour le
   * Web Next.js, « Android » pour l'app mobile). Vide = connexion Google
   * desactivee, les autres methods restent operationnelles.
   */
  GOOGLE_CLIENT_ID: z.string().optional(),
});

export const config = schema.parse(process.env);

/** Origines CORS sous forme de liste. */
export const corsOrigins = config.CORS_ORIGIN.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

export const isProduction = config.NODE_ENV === "production";
