import jwt, { type SignOptions } from "jsonwebtoken";
import { config } from "../config";

export interface TokenPayload {
  sub: string;
  email: string;
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
    if (!sub || !email || (type !== "access" && type !== "refresh")) {
      return null;
    }
    return { sub, email, type };
  } catch {
    return null;
  }
}
