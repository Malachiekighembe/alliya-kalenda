import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";

export const peopleRouter = Router();
peopleRouter.use(requireAuth);

const createSchema = z.object({
  fullName: z.string().min(1),
  phone: z.string().default(""),
  jobTitle: z.string().default(""),
  address: z.string().default(""),
  notes: z.string().default(""),
});

/** GET /api/v1/people — répertoire de l'utilisateur. */
peopleRouter.get("/", async (req, res, next) => {
  try {
    const people = await prisma().person.findMany({
      where: { ownerId: req.user!.id },
      orderBy: { fullName: "asc" },
    });
    res.json(people);
  } catch (error) {
    next(error);
  }
});

/** POST /api/v1/people. */
peopleRouter.post("/", validateBody(createSchema), async (req, res, next) => {
  try {
    const person = await prisma().person.create({
      data: { ...req.body, ownerId: req.user!.id },
    });
    res.status(201).json(person);
  } catch (error) {
    next(error);
  }
});
