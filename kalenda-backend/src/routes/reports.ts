import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { ApiError } from "../errors";

export const reportsRouter = Router();
reportsRouter.use(requireAuth);

const createSchema = z.object({
  projectId: z.uuid(),
  title: z.string().min(1),
  body: z.string().default(""),
  reportDate: z.iso.date().optional(),
});

/** GET /api/v1/reports?projectId=&limit= — rapports d'avancement. */
reportsRouter.get("/", async (req, res, next) => {
  try {
    const projectId = req.query.projectId;
    const limit = Math.min(Number(req.query.limit ?? 50) || 50, 200);
    const reports = await prisma().report.findMany({
      where: {
        ownerId: req.user!.id,
        ...(typeof projectId === "string" && projectId ? { projectId } : {}),
      },
      include: {
        project: { select: { id: true, name: true, reference: true } },
      },
      orderBy: { reportDate: "desc" },
      take: limit,
    });
    res.json(reports);
  } catch (error) {
    next(error);
  }
});

/** POST /api/v1/reports. */
reportsRouter.post(
  "/",
  validateBody(createSchema),
  async (req, res, next) => {
    try {
      const { reportDate, ...data } = req.body;
      const report = await prisma().report.create({
        data: {
          ...data,
          ownerId: req.user!.id,
          reportDate: reportDate ? new Date(reportDate) : new Date(),
        },
      });
      res.status(201).json(report);
    } catch (error) {
      next(error);
    }
  },
);

/** DELETE /api/v1/reports/:id. */
reportsRouter.delete("/:id", async (req, res, next) => {
  try {
    const deleted = await prisma().report.deleteMany({
      where: { id: String(req.params.id), ownerId: req.user!.id },
    });
    if (deleted.count === 0) {
      return next(new ApiError(404, "Rapport introuvable"));
    }
    res.status(204).end();
  } catch (error) {
    next(error);
  }
});