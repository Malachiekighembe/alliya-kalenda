// Seed — crée un utilisateur démo et quelques projets de départ.
// Utilisé par `npm run db:seed` (et automatiquement par `prisma db seed`).
import { PrismaClient } from "@prisma/client";
import { hash } from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  const email = "demo@alliya.cd";
  // bcryptjs v3 : le nombre de rounds se passe directement (plus d'objet { saltRounds }).
  const passwordHash = await hash("demo1234", 10);

  const user = await prisma.user.upsert({
    where: { email },
    update: {},
    create: { email, passwordHash },
  });

  await prisma.profile.upsert({
    where: { id: user.id },
    update: {},
    create: {
      id: user.id,
      fullName: "Démo Alliya",
      companyName: "Alliya Construction",
      phone: "+243 000 000 000",
      currency: "USD",
    },
  });

  const ownerId = user.id;

  // --- Projets ------------------------------------------------------------
  const projects = await prisma.project.findMany({ where: { ownerId } });
  const byName = new Map(projects.map((p) => [p.name, p]));

  const projectSpecs = [
    {
      name: "Résidence Kasaï",
      reference: "AK-2026-001",
      clientName: "Promo Kin",
      clientPhone: "+243 81 000 112",
      location: "Kasaï, Kinshasa",
      description: "Immeuble R+4 de 24 logements, fondations et gros œuvre.",
      status: "active" as const,
      progress: 64,
      contractAmount: 185000,
      plannedBudget: 160000,
      startDate: inDays(-120),
      plannedEndDate: inDays(45),
    },
    {
      name: "Atelier Kalenda",
      reference: "AK-2026-002",
      clientName: "Kalenda SARL",
      clientPhone: "+243 82 445 900",
      location: "Matonge, Kinshasa",
      description: "Rénovation complète d'un atelier de production.",
      status: "active" as const,
      progress: 38,
      contractAmount: 72000,
      plannedBudget: 64000,
      startDate: inDays(-60),
      plannedEndDate: inDays(75),
    },
    {
      name: "Extension école Matonge",
      reference: "AK-2026-003",
      clientName: "Fondation Matonge",
      clientPhone: "+243 84 771 220",
      location: "Matonge, Kinshasa",
      description: "Deux salles de classe et un bloc sanitaire.",
      status: "planned" as const,
      progress: 12,
      contractAmount: 28000,
      plannedBudget: 25000,
      startDate: inDays(10),
      plannedEndDate: inDays(92),
    },
  ];

  for (const spec of projectSpecs) {
    if (byName.has(spec.name)) continue;
    const created = await prisma.project.create({ data: { ...spec, ownerId } });
    byName.set(spec.name, created);
  }

  const kasai = byName.get("Résidence Kasaï")!;
  const atelier = byName.get("Atelier Kalenda")!;
  const ecole = byName.get("Extension école Matonge")!;

  // --- Équipe -------------------------------------------------------------
  const peopleSpecs = [
    ["Jean Kalala", "Conducteur de travaux", "+243 81 245 778", "Kasaï"],
    ["Aline Mbuyi", "Ingénieure structure", "+243 82 610 431", "Matonge"],
    ["Patrick Ilunga", "Chef d’équipe", "+243 84 337 902", "Kasaï"],
    ["Mado Tshibanda", "Électricienne", "+243 89 118 664", "Matonge"],
    ["Gracien Bolingo", "Maçon", "+243 85 902 118", "Kasaï"],
    ["Nathalie Kanku", "Assistante administrative", "+243 83 447 006", "Kasaï"],
  ] as const;

  const people = await prisma.person.findMany({ where: { ownerId } });
  const personByName = new Map(people.map((p) => [p.fullName, p]));

  for (const [fullName, jobTitle, phone, area] of peopleSpecs) {
    if (personByName.has(fullName)) continue;
    const created = await prisma.person.create({
      data: { ownerId, fullName, jobTitle, phone, address: area, notes: "" },
    });
    personByName.set(fullName, created);
  }

  const jean = personByName.get("Jean Kalala")!;
  const aline = personByName.get("Aline Mbuyi")!;
  const patrick = personByName.get("Patrick Ilunga")!;
  const mado = personByName.get("Mado Tshibanda")!;

  const assignments: Array<[string, string]> = [
    [kasai.id, jean.id],
    [kasai.id, patrick.id],
    [kasai.id, mado.id],
    [atelier.id, aline.id],
    [atelier.id, mado.id],
    [ecole.id, jean.id],
  ];
  for (const [projectId, personId] of assignments) {
    await prisma.projectPerson.upsert({
      where: { projectId_personId: { projectId, personId } },
      update: {},
      create: { projectId, personId },
    });
  }

  // --- Activités ---------------------------------------------------------
  const activities = [
    { project: kasai, title: "Contrôle des fondations", description: "Validation des fouilles et ferraillage.", status: "in_progress" as const, priority: "high" as const, dueAt: inDays(2) },
    { project: kasai, title: "Livraison du ciment", description: "Vérifier le bon de livraison.", status: "todo" as const, priority: "normal" as const, dueAt: inDays(4) },
    { project: atelier, title: "Réunion chantier", description: "Point hebdomadaire avec le client.", status: "completed" as const, priority: "normal" as const, dueAt: inDays(-1) },
    { project: ecole, title: "Valider les plans", description: "Retour du bureau de contrôle.", status: "todo" as const, priority: "urgent" as const, dueAt: inDays(6) },
  ];
  for (const item of activities) {
    const exists = await prisma.activity.findFirst({ where: { ownerId, title: item.title, projectId: item.project.id } });
    if (!exists) {
      const { project, ...data } = item;
      await prisma.activity.create({ data: { ...data, ownerId, projectId: project.id, activityDate: inDays(0) } });
    }
  }

  // --- Finances ----------------------------------------------------------
  const payments = await prisma.payment.count({ where: { ownerId } });
  if (payments === 0) {
    await prisma.payment.createMany({ data: [
      { ownerId, projectId: kasai.id, amount: 65000, paymentDate: inDays(-35), method: "Virement", notes: "Acompte" },
      { ownerId, projectId: kasai.id, amount: 42000, paymentDate: inDays(-8), method: "Virement", notes: "Acompte 2" },
      { ownerId, projectId: atelier.id, amount: 28000, paymentDate: inDays(-20), method: "Mobile Money", notes: "Premier acompte" },
    ] });
  }
  const expenses = await prisma.expense.count({ where: { ownerId } });
  if (expenses === 0) {
    await prisma.expense.createMany({ data: [
      { ownerId, projectId: kasai.id, label: "Achat ciment", category: "Matériaux", amount: 18000, expenseDate: inDays(-18) },
      { ownerId, projectId: kasai.id, label: "Location grue", category: "Équipement", amount: 9500, expenseDate: inDays(-5) },
      { ownerId, projectId: atelier.id, label: "Peinture", category: "Finition", amount: 6200, expenseDate: inDays(-3) },
    ] });
  }

  // --- Rapports et messagerie ---------------------------------------------
  const reports = await prisma.report.count({ where: { ownerId } });
  if (reports === 0) {
    await prisma.report.createMany({ data: [
      { ownerId, projectId: kasai.id, title: "Rapport mensuel — Résidence Kasaï", body: "Les fondations avancent conformément au planning.", reportDate: inDays(-7) },
      { ownerId, projectId: atelier.id, title: "Point d'avancement — Atelier", body: "Démolition terminée, préparation des murs en cours.", reportDate: inDays(-2) },
    ] });
  }
  const conversations = await prisma.conversation.count({ where: { ownerId } });
  if (conversations === 0) {
    const conversation = await prisma.conversation.create({ data: { ownerId, projectId: kasai.id, title: "Équipe Résidence Kasaï", recipientLabel: "Jean Kalala" } });
    await prisma.message.createMany({ data: [
      { ownerId, conversationId: conversation.id, projectId: kasai.id, body: "Bonjour, le ferraillage est-il prévu demain ?", sentAt: inDays(-1) },
      { ownerId, conversationId: conversation.id, projectId: kasai.id, body: "Oui, l’équipe arrive à 7h. Nous enverrons le rapport.", sentAt: inDays(-1) },
    ] });
  }

  console.log("Seed terminé : projets, équipe, activités, finances, rapports et messagerie.");
}

function inDays(days: number) {
  const date = new Date();
  date.setUTCHours(12, 0, 0, 0);
  date.setUTCDate(date.getUTCDate() + days);
  return date;
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());