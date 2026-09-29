import { Router } from "express";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";

export const dashboardRouter = Router();
dashboardRouter.use(requireAuth);

const num = (value: unknown) => Number(value ?? 0);

const startOfToday = () => {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
};

/**
 * GET /api/v1/dashboard/summary
 * Agrégats du tableau de bord : compteurs projets, trésorerie du mois,
 * activités du jour, prochaines échéances et discussions non lues.
 */
dashboardRouter.get("/summary", async (req, res, next) => {
  try {
    const ownerId = req.user!.id;
    const today = startOfToday();
    const monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 1);
    const in30days = new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000);

    const [
      projects,
      activitiesToday,
      recentPayments,
      monthPayments,
      monthExpenses,
      dueSoon,
      conversations,
    ] = await Promise.all([
      prisma().project.findMany({
        where: { ownerId },
        orderBy: { plannedEndDate: "asc" },
      }),
      prisma().activity.findMany({
        where: {
          ownerId,
          activityDate: { gte: today, lt: new Date(today.getTime() + 24 * 3600 * 1000) },
        },
        include: { project: { select: { id: true, name: true } } },
        orderBy: { activityDate: "asc" },
      }),
      prisma().payment.findMany({
        where: { ownerId },
        include: { project: { select: { id: true, name: true } } },
        orderBy: { paymentDate: "desc" },
        take: 5,
      }),
      prisma().payment.findMany({
        where: { ownerId, paymentDate: { gte: today, lt: monthEnd } },
        select: { amount: true },
      }),
      prisma().expense.findMany({
        where: { ownerId, expenseDate: { gte: today, lt: monthEnd } },
        select: { amount: true },
      }),
      prisma().project.findMany({
        where: {
          ownerId,
          status: { in: ["active", "planned"] },
          plannedEndDate: { lte: in30days },
        },
        orderBy: { plannedEndDate: "asc" },
        take: 5,
      }),
      prisma().conversation.findMany({
        where: { ownerId },
        include: {
          project: { select: { id: true, name: true } },
          messages: { orderBy: { sentAt: "desc" }, take: 1 },
          _count: { select: { messages: true } },
        },
        orderBy: { updatedAt: "desc" },
        take: 10,
      }),
    ]);

    const totalReceived = monthPayments.reduce((s, p) => s + num(p.amount), 0);
    const totalExpenses = monthExpenses.reduce((s, e) => s + num(e.amount), 0);
    const activeProjects = projects.filter((p) => p.status === "active");

    res.json({
      stats: {
        activeProjects: activeProjects.length,
        totalProjects: projects.length,
        receivedMonth: totalReceived,
        expensesMonth: totalExpenses,
        balanceMonth: totalReceived - totalExpenses,
        activitiesToday: activitiesToday.length,
        unreadMessages: conversations.filter((c) => {
          const last = c.messages[0];
          return last ? last.sentAt.getTime() > c.createdAt.getTime() : false;
        }).length,
      },
      hero: activeProjects[0] ?? projects[0] ?? null,
      activeProjects: activeProjects.slice(0, 4),
      activitiesToday,
      dueSoon,
      recentPayments,
      conversations: conversations.map((conversation) => {
        const last = conversation.messages[0] ?? null;
        return {
          id: conversation.id,
          title: conversation.title,
          project: conversation.project,
          updatedAt: conversation.updatedAt,
          messageCount: conversation._count.messages,
          unread: last && last.sentAt.getTime() > conversation.createdAt.getTime(),
          lastMessage: last
            ? {
                id: last.id,
                body: last.body,
                sentAt: last.sentAt,
                mine: last.ownerId === ownerId,
              }
            : null,
        };
      }),
    });
  } catch (error) {
    next(error);
  }
});