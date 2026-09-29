import jwt, { type SignOptions } from "jsonwebtoken";
import { config } from "../config";

export interface TokenPayload {
  /** Identifiant du compte : c'est lui qui fait foi. */
  sub: string;
  /**
   * E-mail, a titre informatif seulement. Il peut etre nul : un compte peut
   * avoir ete cree avec un seul numero de telephone. Aucun droit ne se
   * deduit de ce champ, tout passe par `sub`.
   */
  email?: string | null;
  type: "access" | "refresh";
}

function sign(
  payload: Omit<TokenPayload, "type">,
  type: TokenPayload["type"],
  expiresIn: string,
): string {
  // `type` n'est pas une option acceptée par jsonwebtoken : il est porté par le
  // payload pour pouvoir distinguer access / refresh à la vérification.
  // Les TTL viennent de variables d'environnement (ex. "15m") et sont validés
  // par jsonwebtoken via le type `StringValue` de la paquet `ms`.
  return jwt.sign({ ...payload, type }, config.JWT_SECRET, {
    expiresIn: expiresIn as SignOptions["expiresIn"],
  });
}

export function signAccessToken(
  payload: Omit<TokenPayload, "type">,
): string {
  return sign(payload, "access", config.JWT_ACCESS_TTL);
}

export function signRefreshToken(
  payload: Omit<TokenPayload, "type">,
): string {
  return sign(payload, "refresh", config.JWT_REFRESH_TTL);
}

/** Vérifie signature + expiration ; renvoie le payload ou null. */
export function verifyToken(token: string): TokenPayload | null {
  try {
    const decoded = jwt.verify(token, config.JWT_SECRET);
    if (typeof decoded === "string") return null;
    const { sub, email, type } = decoded as jwt.JwtPayload &
      Partial<TokenPayload>;
    // Seul `sub` est obligatoire : l'e-mail peut manquer sur un compte cree
    // avec un numero de telephone.
    if (!sub || (type !== "access" && type !== "refresh")) {
      return null;
    }
    return { sub, email: email ?? null, type };
  } catch {
    return null;
  }
}
