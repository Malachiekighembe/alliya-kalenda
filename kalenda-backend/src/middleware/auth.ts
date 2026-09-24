import type { NextFunction, Request, Response } from "express";
import { unauthorized } from "../errors";
import { verifyToken } from "../lib/jwt";

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: { id: string; email: string };
    }
  }
}

/** Exige un header `Authorization: Bearer <token>` valide (JWT access). */
export function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) return next(unauthorized());

  const payload = verifyToken(header.slice("Bearer ".length).trim());
  if (!payload) return next(unauthorized("Token invalide ou expiré"));

  req.user = { id: payload.sub, email: payload.email };
  next();
}
