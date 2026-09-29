import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { ApiError } from "../errors";

export const conversationsRouter = Router();
conversationsRouter.use(requireAuth);

const createSchema = z.object({
  title: z.string().min(1),
  projectId: z.uuid().optional(),
  recipientLabel: z.string().default(""),
});

/** Sérialise un nombre Prisma (Decimal) en nombre JS. */
const num = (value: unknown) => Number(value ?? 0);

/**
 * GET /api/v1/conversations
 * Discussions de l'utilisateur, la plus récente en tête, avec le dernier
 * message et un indicateur de non-lu (le dernier message est-il récent et
 * écrit par un tiers ?).
 */
conversationsRouter.get("/", async (req, res, next) => {
  try {
    const conversations = await prisma().conversation.findMany({
      where: { ownerId: req.user!.id },
      include: {
        project: { select: { id: true, name: true, reference: true } },
        messages: { orderBy: { sentAt: "desc" }, take: 1 },
        _count: { select: { messages: true } },
      },
      orderBy: { updatedAt: "desc" },
    });

    res.json(
      conversations.map((conversation) => {
        const last = conversation.messages[0] ?? null;
        return {
          id: conversation.id,
          title: conversation.title,
          recipientLabel: conversation.recipientLabel,
          project: conversation.project,
          projectId: conversation.projectId,
          createdAt: conversation.createdAt,
          updatedAt: conversation.updatedAt,
          messageCount: conversation._count.messages,
          unread: last && last.sentAt > conversation.createdAt ? 1 : 0,
          lastMessage: last
            ? {
                id: last.id,
                body: last.body,
                sentAt: last.sentAt,
                mine: last.ownerId === req.user!.id,
              }
            : null,
        };
      }),
    );
  } catch (error) {
    next(error);
  }
});

/** GET /api/v1/conversations/:id — détail d'une discussion. */
conversationsRouter.get("/:id", async (req, res, next) => {
  try {
    const id = String(req.params.id);
    const conversation = await prisma().conversation.findFirst({
      where: { id, ownerId: req.user!.id },
      include: { project: true },
    });
    if (!conversation) {
      return next(new ApiError(404, "Discussion introuvable"));
    }
    res.json(conversation);
  } catch (error) {
    next(error);
  }
});

/** POST /api/v1/conversations — ouvre une discussion (sur un chantier ou libre). */
conversationsRouter.post(
  "/",
  validateBody(createSchema),
  async (req, res, next) => {
    try {
      const { projectId, ...data } = req.body;
      const conversation = await prisma().conversation.create({
        data: { ...data, ownerId: req.user!.id, projectId: projectId ?? null },
      });
      res.status(201).json(conversation);
    } catch (error) {
      next(error);
    }
  },
);

/** DELETE /api/v1/conversations/:id. */
conversationsRouter.delete("/:id", async (req, res, next) => {
  try {
    const id = String(req.params.id);
    const deleted = await prisma().conversation.deleteMany({
      where: { id, ownerId: req.user!.id },
    });
    if (deleted.count === 0) {
      return next(new ApiError(404, "Discussion introuvable"));
    }
    res.status(204).end();
  } catch (error) {
    next(error);
  }
});

/** GET /api/v1/conversations/:id/messages?limit= — fil d'une discussion. */
conversationsRouter.get("/:id/messages", async (req, res, next) => {
  try {
    const id = String(req.params.id);
    const limit = Math.min(Number(req.query.limit ?? 100) || 100, 300);
    const conversation = await prisma().conversation.findFirst({
      where: { id, ownerId: req.user!.id },
      select: { id: true },
    });
    if (!conversation) {
      return next(new ApiError(404, "Discussion introuvable"));
    }
    const messages = await prisma().message.findMany({
      where: { conversationId: id },
      include: {
        attachments: {
          select: { id: true, path: true, filename: true, mimeType: true },
        },
      },
      orderBy: { sentAt: "asc" },
      take: limit,
    });
    res.json(
      messages.map((message) => ({
        ...message,
        mine: message.ownerId === req.user!.id,
        amountHint: num(message.body) || null,
      })),
    );
  } catch (error) {
    next(error);
  }
});

/** POST /api/v1/conversations/:id/messages — envoie un message. */
conversationsRouter.post(
  "/:id/messages",
  validateBody(
    z.object({
      body: z.string().min(1),
      projectId: z.uuid().optional(),
    }),
  ),
  async (req, res, next) => {
    try {
      const conversationId = String(req.params.id);
      const conversation = await prisma().conversation.findFirst({
        where: { id: conversationId, ownerId: req.user!.id },
        select: { id: true, projectId: true },
      });
      if (!conversation) {
        return next(new ApiError(404, "Discussion introuvable"));
      }
      const message = await prisma().message.create({
        data: {
          body: req.body.body,
          ownerId: req.user!.id,
          conversationId,
          projectId: req.body.projectId ?? conversation.projectId ?? null,
        },
        include: {
          attachments: {
            select: { id: true, path: true, filename: true, mimeType: true },
          },
        },
      });
      await prisma().conversation.update({
        where: { id: conversationId },
        data: { updatedAt: new Date() },
      });
      res.status(201).json({ ...message, mine: true });
    } catch (error) {
      next(error);
    }
  },
);