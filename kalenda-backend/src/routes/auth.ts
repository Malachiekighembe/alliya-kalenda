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

/** Format de numero accepte : chiffres, espaces et separateurs usuels. */
const phonePattern = /^\+?[0-9\s().-]{6,20}$/;

/** Connexion : un e-mail OU un numero de telephone. */
const credentialsSchema = z.object({
  /** E-mail ou numero : la connexion accepte les deux. */
  identifier: z.string().min(3),
  password: z.string().min(1),
});

const registerSchema = z
  .object({
    email: z.email().optional(),
    phone: z
      .string()
      .regex(phonePattern, "Numéro de téléphone invalide.")
      .optional(),
    password: z.string().min(8),
    /** Nom de famille, puis prenom : l'ordre suit l'usage local. */
    lastName: z.string().min(1, "Le nom est requis."),
    firstName: z.string().min(1, "Le post-nom est requis."),
    /**
     * Date de naissance au format AAAA-MM-JJ. Facultative : l'utilisateur
     * peut la completer plus tard depuis son profil.
     */
    birthDate: z
      .string()
      .regex(/^\d{4}-\d{2}-\d{2}$/, "Date de naissance invalide.")
      .optional()
      .or(z.literal("").transform(() => undefined)),
    /** Module choisi lors du parcours d'inscription (cf. lib/modules.ts). */
    module: z.string().min(1).default("electricite"),
    /** Metier exerce : specialite du module, stocke dans `job_title`. */
    jobTitle: z.string().default(""),
    companyName: z.string().default(""),
    certifications: z.string().default(""),
  })
  // Au moins l'un des deux : un compte sans moyen de contact ne sert a rien.
  .refine((data) => data.email || data.phone, {
    message: "Renseignez un e-mail ou un numéro de téléphone.",
    path: ["email"],
  });

const refreshSchema = z.object({ refreshToken: z.string().min(1) });

const googleSchema = z.object({
  /** Jeton d'identite renvoye par Google Identity Services / google_sign_in. */
  credential: z.string().min(20),
});

/**
 * Achèvement du parcours apres une identité Google inconnue.
 *
 * Google ne donne qu'une identité : le module et le mot de passe restent
 * choisis par l'utilisateur, sinon le compte serait incomplet.
 */
const googleRegisterSchema = googleSchema.extend({
  module: z.string().min(1).default("electricite"),
  jobTitle: z.string().default(""),
  companyName: z.string().default(""),
  phone: z
    .string()
    .regex(phonePattern, "Numéro de téléphone invalide.")
    .optional(),
  certifications: z.string().default(""),
  /** Mot de passe choisi par l'utilisateur : il devient son accès direct. */
  password: z.string().min(8),
});

/**
 * Normalise un numéro : espaces, points, tirets et parenthèses sont retirés,
 * pour que « +243 81 000 0000 » et « +243810000000 » désignent le même compte.
 */
function normalizePhone(value: string) {
  return value.replace(/[\s().-]/g, "");
}

/** Déduit le type d'un identifiant de connexion : la présence d'un « @ » suffit. */
function parseIdentifier(value: string) {
  const trimmed = value.trim();
  return trimmed.includes("@")
    ? { kind: "email" as const, value: trimmed.toLowerCase() }
    : { kind: "phone" as const, value: normalizePhone(trimmed) };
}

/** Retrouve un compte par e-mail ou par téléphone. */
async function findByIdentifier(identifier: string) {
  const parsed = parseIdentifier(identifier);
  return prisma().user.findUnique({
    where:
      parsed.kind === "email" ? { email: parsed.value } : { phone: parsed.value },
  });
}

/**
 * Repartit un nom complet en nom de famille et prenom.
 *
 * L'ordre retenu est nom puis prenom, comme les champs du formulaire.
 * `fullName` est reconstitue pour les ecrans qui l'affichent encore.
 */
function splitName(fullName: string) {
  const parts = fullName.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) {
    return { lastName: "", firstName: "", fullName: "" };
  }
  const [first, ...rest] = parts;
  return { lastName: rest.join(" "), firstName: first, fullName };
}

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
  return {
    sub: payload.sub,
    email: payload.email.toLowerCase(),
    name: payload.name ?? "",
  };
}

function issueTokens(user: { id: string; email: string | null; phone?: string | null }) {
  const payload = { sub: user.id, email: user.email };
  return {
    accessToken: signAccessToken(payload),
    refreshToken: signRefreshToken(payload),
    user: { id: user.id, email: user.email, phone: user.phone ?? null },
  };
}

/** POST /api/v1/auth/register — crée le compte + profil par défaut. */
authRouter.post(
  "/register",
  validateBody(registerSchema),
  async (req, res, next) => {
    try {
      const {
        email: rawEmail,
        phone: rawPhone,
        password,
        lastName,
        firstName,
        birthDate,
        module,
        jobTitle,
        companyName,
        certifications,
      } = req.body;

      // Un e-mail ou un numero, normalises avant confrontation a la base :
      // deux saisies differentes pour le meme numero doivent se percuter.
      const email = rawEmail ? rawEmail.toLowerCase() : null;
      const phone = rawPhone ? normalizePhone(rawPhone) : null;

      if (email && (await prisma().user.findUnique({ where: { email } }))) {
        throw conflict("Un compte existe déjà avec cet e-mail.");
      }
      if (phone && (await prisma().user.findUnique({ where: { phone } }))) {
        throw conflict("Un compte existe déjà avec ce numéro.");
      }

      // bcryptjs v3 : rounds en argument direct, l'objet { saltRounds } est refusé.
      const passwordHash = await hash(password, 10);
      const user = await prisma().user.create({
        data: {
          email,
          phone,
          passwordHash,
          profile: {
            create: {
              lastName,
              firstName,
              // Date facultative : absente tant que l'utilisateur ne la
              // renseigne pas depuis son profil.
              birthDate: birthDate ? new Date(`${birthDate}T00:00:00Z`) : null,
              // `fullName` reste renseigne pour les ecrans existants.
              fullName: `${lastName} ${firstName}`.trim(),
              module,
              jobTitle,
              companyName,
              // Le telephone vit desormais sur `users` : il sert a la
              // connexion. On le garde aussi au profil, ou les ecrans de
              // reglages l'affichent.
              phone: phone ?? "",
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

/** POST /api/v1/auth/login — accepte un e-mail ou un numero de telephone. */
authRouter.post(
  "/login",
  validateBody(credentialsSchema),
  async (req, res, next) => {
    try {
      const { identifier, password } = req.body;
      const user = await findByIdentifier(identifier);
      // Message unique : ne pas reveler si le compte existe, seulement
      // si le couple est invalide.
      if (!user || !(await compare(password, user.passwordHash))) {
        throw unauthorized("Identifiant ou mot de passe incorrect.");
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
 * Verifie le jeton Google, puis :
 *  - compte deja relie  -> session ouverte directement ;
 *  - identite inconnue -> AUCUN compte n'est cree. La reponse demande au
 *    client de derouler le parcours d'inscription, et c'est
 *    POST /api/v1/auth/google/register qui crea le compte.
 *
 * Avant, un compte etait cree automatiquement avec un mot de passe aleatoire.
 * L'utilisateur se retrouvait avec un profil sans module ni metier, qu'il
 * ne pouvait pas completer ensuite. Google ne sert plus qu'a prouver
 * l'identite.
 */
authRouter.post(
  "/google",
  validateBody(googleSchema),
  async (req, res, next) => {
    try {
      const { sub, email, name } = await verifyGoogleCredential(req.body.credential);

      // Le `sub` est la cle de rapprochement : l'e-mail Google peut changer.
      const linked = await prisma().user.findUnique({ where: { googleSub: sub } });
      if (linked) {
        res.json(issueTokens(linked));
        return;
      }

      // Un compte existe peut-etre deja avec la meme adresse, cree par e-mail.
      // On ne l'ecrase pas : on propose de le relier, ce que l'utilisateur
      // confirme en fournissant son mot de passe.
      const byEmail = await prisma().user.findUnique({ where: { email } });

      res.status(409).json({
        error: {
          code: "GOOGLE_ACCOUNT_REQUIRED",
          message: byEmail
            ? "Un compte existe déjà avec cette adresse. Confirmez votre mot de passe pour le relier à Google."
            : "Complétez votre inscription pour continuer.",
          email,
          name,
          /** Un compte de meme e-mail attend d'etre relie plutot que cree. */
          requiresLink: Boolean(byEmail),
        },
      });
    } catch (error) {
      next(error);
    }
  },
);

/**
 * POST /api/v1/auth/google/register
 *
 * Acheve l'inscription d'une identite Google : l'utilisateur a choisi son
 * module, son metier et son mot de passe. Le compte cree est relie au `sub`
 * Google, donc la prochaine connexion IRA directement.
 *
 * Si un compte existe avec la meme adresse, on le relie au lieu d'en creer
 * un second : c'est le cas « requiresLink » renvoye par /auth/google.
 */
authRouter.post(
  "/google/register",
  validateBody(googleRegisterSchema),
  async (req, res, next) => {
    try {
      const {
        module,
        jobTitle,
        companyName,
        certifications,
        password,
        phone: rawPhone,
      } = req.body;
      const { sub, email, name } = await verifyGoogleCredential(req.body.credential);
      const phone = rawPhone ? normalizePhone(rawPhone) : null;

      // Appeler deux fois le bouton ne doit pas creer deux comptes.
      const alreadyLinked = await prisma().user.findUnique({ where: { googleSub: sub } });
      if (alreadyLinked) {
        res.json(issueTokens(alreadyLinked));
        return;
      }

      if (phone && (await prisma().user.findUnique({ where: { phone } }))) {
        throw conflict("Un compte existe déjà avec ce numéro.");
      }

      const passwordHash = await hash(password, 10);
      const existingByEmail = await prisma().user.findUnique({ where: { email } });

      if (existingByEmail) {
        // Reliement : le compte garde son historique, on y ajoute la cle
        // Google et le module choisi, et on impose le nouveau mot de passe.
        const updated = await prisma().user.update({
          where: { id: existingByEmail.id },
          data: {
            googleSub: sub,
            phone: phone ?? existingByEmail.phone,
            passwordHash,
            profile: {
              update: {
                module,
                jobTitle,
                companyName,
                certifications,
              },
            },
          },
        });
        res.json(issueTokens(updated));
        return;
      }

      const user = await prisma().user.create({
        data: {
          email,
          phone,
          googleSub: sub,
          passwordHash,
          profile: {
            create: {
              // Google fournit un nom unique : on repartit le premier mot en
              // prenom, le reste en nom de famille.
              ...splitName(name || email.split("@")[0]),
              module,
              jobTitle,
              companyName,
              phone: phone ?? "",
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
