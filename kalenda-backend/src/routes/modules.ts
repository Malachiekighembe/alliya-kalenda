import { Router } from "express";
import { prisma } from "../lib/prisma";

export const modulesRouter = Router();

/**
 * GET /api/v1/modules
 *
 * Catalogue des modules d'activite. Volontairement public : l'ecran de
 * connexion doit proposer le choix du module avant qu'une session existe.
 * L'API reste la seule source — aucun module n'est code en dur dans le client.
 */
modulesRouter.get("/", async (_req, res, next) => {
  try {
    const rows = await prisma().module.findMany({
      orderBy: [{ position: "asc" }, { label: "asc" }],
    });

    res.json(
      rows.map((row) => ({
        id: row.id,
        label: row.label,
        status: row.status,
        promise: row.promise,
        cover: row.cover,
        icon: row.icon,
        highlights: row.highlights,
        fields: row.fields,
      })),
    );
  } catch (error) {
    next(error);
  }
});
