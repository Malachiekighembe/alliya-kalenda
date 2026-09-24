import jwt, { type SignOptions } from "jsonwebtoken";
import { config } from "../config";

export interface TokenPayload {
  sub: string;
  email: string;
}

export function signAccessToken(payload: TokenPayload): string {
  return jwt.sign(payload, config.JWT_SECRET, {
    expiresIn: config.JWT_ACCESS_TTL,
    type: "access",
  } as SignOptions);
}

export function signRefreshToken(payload: TokenPayload): string {
  return jwt.sign(payload, config.JWT_SECRET, {
    expiresIn: config.JWT_REFRESH_TTL,
    type: "refresh",
  } as SignOptions);
}

/** Vérifie signature + expiration ; renvoie le payload ou null. */
export function verifyToken(token: string): TokenPayload | null {
  try {
    const decoded = jwt.verify(token, config.JWT_SECRET);
    if (typeof decoded === "string") return null;
    const { sub, email } = decoded as jwt.JwtPayload & Partial<TokenPayload>;
    if (!sub || !email) return null;
    return { sub, email };
  } catch {
    return null;
  }
}
