import { randomBytes } from "node:crypto";

import { Router } from "express";
import { compare, hash } from "bcryptjs";
import { OAuth2Client } from "google-auth-library";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { config } from "../config";
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
  /** Module choisi lors du parcours d'inscription (cf. lib/modules.ts). */
  module: z.string().min(1).default("electricite"),
  /** Metier exerce : specialite du module, stocke dans `job_title`. */
  jobTitle: z.string().default(""),
  companyName: z.string().default(""),
  phone: z.string().default(""),
  certifications: z.string().default(""),
});

const refreshSchema = z.object({ refreshToken: z.string().min(1) });

const googleSchema = z.object({
  /** Jeton d'identite renvoye par Google Identity Services / google_sign_in. */
  credential: z.string().min(20),
});

const googleClient = new OAuth2Client(
  config.GOOGLE_CLIENT_ID || "client-id-non-configure.apps.googleusercontent.com",
);

/**
 * Verifie un jeton Google et renvoie une charge utile `{ email, sub }`.
 *
 * La signature est verifiee contre les cles publiques Google (JWKS, avec
 * mise en cache) et l'audience doit correspondre a notre Client ID : cela
 * empeche la reutilisation d'un jeton emis pour une autre application.
 */
async function verifyGoogleCredential(credential: string) {
  if (!config.GOOGLE_CLIENT_ID) {
    throw new ApiError(
      503,
      "La connexion Google n'est pas configurée sur ce serveur.",
    );
  }

  const ticket = await googleClient.verifyIdToken({
    idToken: credential,
    audience: config.GOOGLE_CLIENT_ID,
  });
  const payload = ticket.getPayload();

  if (!payload?.email) {
    throw unauthorized("Ce compte Google ne fournit pas d'adresse e-mail.");
  }
  // Google ne renvoie `email_verified` que pour les jetons d'identite.
  if (payload.email_verified === false) {
    throw unauthorized("L'adresse e-mail Google n'est pas vérifiée.");
  }
  return { email: payload.email.toLowerCase(), name: payload.name ?? "" };
}

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
      const { email, password, fullName, module, jobTitle, companyName, phone, certifications } = req.body;
      const existing = await prisma().user.findUnique({ where: { email } });
      if (existing) throw conflict("Un compte existe déjà avec cet email.");

      // bcryptjs v3 : rounds en argument direct, l'objet { saltRounds } est refusé.
      const passwordHash = await hash(password, 10);
      const user = await prisma().user.create({
        data: {
          email,
          passwordHash,
          profile: {
            create: {
              fullName,
              module,
              jobTitle,
              companyName,
              phone,
              certifications,
            },
          },
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
      if (!user || !(await compare(password, user.passwordHash))) {
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
    if (payload.type !== "refresh") {
      throw unauthorized("Un access token ne peut pas être rafraîchi.");
    }
    res.json({
      accessToken: signAccessToken({ sub: payload.sub, email: payload.email }),
      refreshToken: signRefreshToken({ sub: payload.sub, email: payload.email }),
      user: { id: payload.sub, email: payload.email },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/v1/auth/google
 *
 * Verifie le jeton Google puis ouvre une session Alliya Kalenda :
 *  - compte existant  -> on reutilise la ligne `users` ;
 *  - compte inconnu   -> creation avec un mot de passe aleatoire non
 *    devinable, donc inaccessible par la route /auth/login.
 *
 * Le backend reste ainsi seul emetteur de ses JWT : Google ne sert qu'a
 * prouver l'identite.
 */
authRouter.post(
  "/google",
  validateBody(googleSchema),
  async (req, res, next) => {
    try {
      const { email, name } = await verifyGoogleCredential(req.body.credential);

      const existing = await prisma().user.findUnique({ where: { email } });
      const user =
        existing ??
        (await prisma().user.create({
          data: {
            email,
            passwordHash: await hash(randomBytes(32).toString("hex"), 10),
            profile: {
              create: {
                fullName: name || email.split("@")[0],
              },
            },
          },
        }));

      res.json(issueTokens(user));
    } catch (error) {
      next(error);
    }
  },
);

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
