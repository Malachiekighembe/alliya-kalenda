import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";

export const financesRouter = Router();
financesRouter.use(requireAuth);

const paymentSchema = z.object({
  projectId: z.uuid(),
  amount: z.coerce.number().positive(),
  paymentDate: z.iso.date(),
  method: z.string().default(""),
  notes: z.string().default(""),
});

const expenseSchema = z.object({
  projectId: z.uuid(),
  label: z.string().min(1),
  category: z.string().default(""),
  amount: z.coerce.number().positive(),
  expenseDate: z.iso.date(),
  notes: z.string().default(""),
});

/** GET /api/v1/finances/payments?projectId= — encaissements. */
financesRouter.get("/payments", async (req, res, next) => {
  try {
    const projectId = req.query.projectId;
    const payments = await prisma().payment.findMany({
      where: {
        ownerId: req.user!.id,
        ...(typeof projectId === "string" && projectId ? { projectId } : {}),
      },
      orderBy: { paymentDate: "desc" },
    });
    res.json(payments);
  } catch (error) {
    next(error);
  }
});

/** POST /api/v1/finances/payments. */
financesRouter.post(
  "/payments",
  validateBody(paymentSchema),
  async (req, res, next) => {
    try {
      const payment = await prisma().payment.create({
        data: {
          ...req.body,
          paymentDate: new Date(req.body.paymentDate),
          ownerId: req.user!.id,
        },
      });
      res.status(201).json(payment);
    } catch (error) {
      next(error);
    }
  },
);

/** GET /api/v1/finances/expenses?projectId= — dépenses. */
financesRouter.get("/expenses", async (req, res, next) => {
  try {
    const projectId = req.query.projectId;
    const expenses = await prisma().expense.findMany({
      where: {
        ownerId: req.user!.id,
        ...(typeof projectId === "string" && projectId ? { projectId } : {}),
      },
      orderBy: { expenseDate: "desc" },
    });
    res.json(expenses);
  } catch (error) {
    next(error);
  }
});

/** POST /api/v1/finances/expenses. */
financesRouter.post(
  "/expenses",
  validateBody(expenseSchema),
  async (req, res, next) => {
    try {
      const expense = await prisma().expense.create({
        data: {
          ...req.body,
          expenseDate: new Date(req.body.expenseDate),
          ownerId: req.user!.id,
        },
      });
      res.status(201).json(expense);
    } catch (error) {
      next(error);
    }
  },
);
