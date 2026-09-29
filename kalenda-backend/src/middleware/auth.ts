import type { NextFunction, Request, Response } from "express";
import { unauthorized } from "../errors";
import { verifyToken } from "../lib/jwt";

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      user?: { id: string; email: string | null };
    }
  }
}

/** Exige un header `Authorization: Bearer <token>` valide (JWT access). */
export function requireAuth(req: Request, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) return next(unauthorized());

  const payload = verifyToken(header.slice("Bearer ".length).trim());
  if (!payload) return next(unauthorized("Token invalide ou expiré"));
  // Un refresh token ne doit jamais autoriser un appel API.
  if (payload.type !== "access") {
    return next(unauthorized("Refresh token non accepté ici"));
  }

  req.user = { id: payload.sub, email: payload.email ?? null };
  next();
}
