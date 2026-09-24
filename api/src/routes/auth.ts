import { Router } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import {
  signAccessToken,
  signRefreshToken,
  verifyToken,
} from "../lib/jwt";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { ApiError, conflict, unauthorized } from "../errors";

export const authRouter = Router();

const credentialsSchema = z.object({
  email: z.email(),
  password: z.string().min(8),
});

const registerSchema = credentialsSchema.extend({
  fullName: z.string().min(1),
});

const refreshSchema = z.object({ refreshToken: z.string().min(1) });

function issueTokens(user: { id: string; email: string }) {
  const payload = { sub: user.id, email: user.email };
  return {
    accessToken: signAccessToken(payload),
    refreshToken: signRefreshToken(payload),
    user: { id: user.id, email: user.email },
  };
}

/** POST /api/v1/auth/register — crée le compte + profil par défaut. */
authRouter.post(
  "/register",
  validateBody(registerSchema),
  async (req, res, next) => {
    try {
      const { email, password, fullName } = req.body;
      const existing = await prisma().user.findUnique({ where: { email } });
      if (existing) throw conflict("Un compte existe déjà avec cet email.");

      const passwordHash = await bcrypt.hash(password, 10);
      const user = await prisma().user.create({
        data: {
          email,
          passwordHash,
          profile: { create: { fullName } },
        },
      });
      res.status(201).json(issueTokens(user));
    } catch (error) {
      next(error);
    }
  },
);

/** POST /api/v1/auth/login. */
authRouter.post(
  "/login",
  validateBody(credentialsSchema),
  async (req, res, next) => {
    try {
      const { email, password } = req.body;
      const user = await prisma().user.findUnique({ where: { email } });
      if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
        throw unauthorized("Email ou mot de passe incorrect.");
      }
      res.json(issueTokens(user));
    } catch (error) {
      next(error);
    }
  },
);

/** POST /api/v1/auth/refresh — échange un refresh token contre un nouveau couple. */
authRouter.post("/refresh", validateBody(refreshSchema), (req, res, next) => {
  try {
    const payload = verifyToken(req.body.refreshToken);
    if (!payload) throw unauthorized("Refresh token invalide ou expiré.");
    res.json({
      accessToken: signAccessToken({ sub: payload.sub, email: payload.email }),
      refreshToken: signRefreshToken({ sub: payload.sub, email: payload.email }),
      user: { id: payload.sub, email: payload.email },
    });
  } catch (error) {
    next(error);
  }
});

/** GET /api/v1/auth/me — profil de l'utilisateur connecté. */
authRouter.get("/me", requireAuth, async (req, res, next) => {
  try {
    const user = await prisma().user.findUnique({
      where: { id: req.user!.id },
      include: { profile: true },
    });
    if (!user) throw new ApiError(404, "Compte introuvable.");
    const { passwordHash, ...safe } = user;
    res.json(safe);
  } catch (error) {
    next(error);
  }
});
