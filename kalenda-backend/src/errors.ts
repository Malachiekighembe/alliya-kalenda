/** Erreur métier exposée au client avec un statut HTTP. */
export class ApiError extends Error {
  readonly status: number;
  readonly details?: unknown;

  constructor(status: number, message: string, details?: unknown) {
    super(message);
    this.name = "ApiError";
    this.status = status;
    this.details = details;
  }
}

export const unauthorized = (message = "Authentification requise") =>
  new ApiError(401, message);

export const forbidden = (message = "Accès refusé") => new ApiError(403, message);

export const notFound = (message = "Ressource introuvable") =>
  new ApiError(404, message);

export const conflict = (message: string) => new ApiError(409, message);
