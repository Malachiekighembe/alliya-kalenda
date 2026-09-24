import type { NextFunction, Request, Response } from "express";
import { ApiError } from "../errors";
import { isProduction } from "../config";

/** 404 : toute route non appariée arrive ici. */
export function notFoundHandler(req: Request, _res: Response, next: NextFunction) {
  next(new ApiError(404, `Route introuvable : ${req.method} ${req.path}`));
}

/** Gestionnaire d'erreurs central (toujours en dernier). */
export function errorHandler(
  err: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
) {
  if (err instanceof ApiError) {
    return res
      .status(err.status)
      .json({ error: { message: err.message, details: err.details ?? null } });
  }

  // JSON malformé (express.json).
  if (
    typeof err === "object" &&
    err !== null &&
    "type" in err &&
    (err as { type?: string }).type === "entity.parse.failed"
  ) {
    return res
      .status(400)
      .json({ error: { message: "JSON invalide", details: null } });
  }

  console.error(err);
  return res.status(500).json({
    error: {
      message: "Erreur interne du serveur",
      details: isProduction ? null : String(err),
    },
  });
}
