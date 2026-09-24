import type { NextFunction, Request, Response } from "express";
import { type ZodType } from "zod";
import { ApiError } from "../errors";

/** Valide et remplace `req.body` avec le schéma Zod fourni. */
export function validateBody<T>(schema: ZodType<T>) {
  return (req: Request, _res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      return next(
        new ApiError(422, "Corps de requête invalide", result.error.issues),
      );
    }
    req.body = result.data;
    next();
  };
}
