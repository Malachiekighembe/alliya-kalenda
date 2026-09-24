import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";

export const activitiesRouter = Router();
activitiesRouter.use(requireAuth);

const createSchema = z.object({
  title: z.string().min(1),
  projectId: z.uuid().optional(),
  description: z.string().default(""),
  status: z.enum(["todo", "in_progress", "completed"]).default("todo"),
  priority: z.enum(["low", "normal", "high", "urgent"]).default("normal"),
  activityDate: z.iso.date().optional(),
  notes: z.string().default(""),
});

/** GET /api/v1/activities?date=YYYY-MM-DD — agenda du jour ou complet. */
activitiesRouter.get("/", async (req, res, next) => {
  try {
    const date = req.query.date;
    const activities = await prisma().activity.findMany({
      where: {
        ownerId: req.user!.id,
        ...(typeof date === "string" && date
          ? { activityDate: new Date(date) }
          : {}),
      },
      include: { project: { select: { id: true, name: true } } },
      orderBy: [{ activityDate: "asc" }, { createdAt: "asc" }],
    });
    res.json(activities);
  } catch (error) {
    next(error);
  }
});

/** POST /api/v1/activities. */
activitiesRouter.post(
  "/",
  validateBody(createSchema),
  async (req, res, next) => {
    try {
      const { activityDate, ...data } = req.body;
      const activity = await prisma().activity.create({
        data: {
          ...data,
          ownerId: req.user!.id,
          ...(activityDate ? { activityDate: new Date(activityDate) } : {}),
        },
      });
      res.status(201).json(activity);
    } catch (error) {
      next(error);
    }
  },
);
