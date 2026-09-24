import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { notFound } from "../errors";

export const projectsRouter = Router();
projectsRouter.use(requireAuth);

const projectStatus = z.enum([
  "planned",
  "active",
  "paused",
  "completed",
  "cancelled",
]);

const createSchema = z.object({
  name: z.string().min(1),
  reference: z.string().default(""),
  clientName: z.string().default(""),
  clientPhone: z.string().default(""),
  location: z.string().default(""),
  description: z.string().default(""),
  contractAmount: z.coerce.number().nonnegative().default(0),
  status: projectStatus.default("planned"),
  progress: z.coerce.number().min(0).max(100).default(0),
  plannedEndDate: z.iso.datetime({ offset: true }).optional(),
});

const updateSchema = createSchema.partial();

/** GET /api/v1/projects?status=active — liste filtrable, triée du plus récent. */
projectsRouter.get("/", async (req, res, next) => {
  try {
    const status = req.query.status;
    const projects = await prisma().project.findMany({
      where: {
        ownerId: req.user!.id,
        ...(typeof status === "string" && status
          ? { status: status as z.infer<typeof projectStatus> }
          : {}),
      },
      orderBy: { createdAt: "desc" },
    });
    res.json(projects);
  } catch (error) {
    next(error);
  }
});

/** POST /api/v1/projects. */
projectsRouter.post("/", validateBody(createSchema), async (req, res, next) => {
  try {
    const { plannedEndDate, ...data } = req.body;
    const project = await prisma().project.create({
      data: {
        ...data,
        ownerId: req.user!.id,
        ...(plannedEndDate ? { plannedEndDate: new Date(plannedEndDate) } : {}),
      },
    });
    res.status(201).json(project);
  } catch (error) {
    next(error);
  }
});

/** GET /api/v1/projects/:id. */
projectsRouter.get("/:id", async (req, res, next) => {
  try {
    const project = await prisma().project.findFirst({
      where: { id: req.params.id, ownerId: req.user!.id },
      include: { phases: { orderBy: { position: "asc" } } },
    });
    if (!project) throw notFound("Projet introuvable.");
    res.json(project);
  } catch (error) {
    next(error);
  }
});

/** PATCH /api/v1/projects/:id. */
projectsRouter.patch(
  "/:id",
  validateBody(updateSchema),
  async (req, res, next) => {
    try {
      const { plannedEndDate, ...data } = req.body;
      const result = await prisma().project.updateMany({
        where: { id: req.params.id, ownerId: req.user!.id },
        data: {
          ...data,
          ...(plannedEndDate ? { plannedEndDate: new Date(plannedEndDate) } : {}),
        },
      });
      if (result.count === 0) throw notFound("Projet introuvable.");
      const project = await prisma().project.findUnique({
        where: { id: req.params.id },
      });
      res.json(project);
    } catch (error) {
      next(error);
    }
  },
);

/** DELETE /api/v1/projects/:id. */
projectsRouter.delete("/:id", async (req, res, next) => {
  try {
    const result = await prisma().project.deleteMany({
      where: { id: req.params.id, ownerId: req.user!.id },
    });
    if (result.count === 0) throw notFound("Projet introuvable.");
    res.status(204).end();
  } catch (error) {
    next(error);
  }
});
