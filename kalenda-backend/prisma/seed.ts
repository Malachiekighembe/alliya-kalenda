// Seed — crée un utilisateur démo et quelques projets de départ.
// Utilisé par `npm run db:seed` (et automatiquement par `prisma db seed`).
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

async function main() {
  const email = "demo@alliya.cd";
  const passwordHash = await bcrypt.hash("demo1234", 10);

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

  const existing = await prisma.project.count({ where: { ownerId: user.id } });
  if (existing === 0) {
    const inDays = (days: number) =>
      new Date(Date.now() + days * 24 * 60 * 60 * 1000);

    await prisma.project.createMany({
      data: [
        {
          ownerId: user.id,
          name: "Résidence Kasaï",
          reference: "AK-2026-001",
          clientName: "Promo Kin",
          location: "Kasaï, Kinshasa",
          status: "active",
          progress: 64,
          contractAmount: 185000,
          plannedEndDate: inDays(45),
        },
        {
          ownerId: user.id,
          name: "Atelier Kalenda",
          reference: "AK-2026-002",
          clientName: "Kalenda SARL",
          location: "Matonge, Kinshasa",
          status: "active",
          progress: 38,
          contractAmount: 72000,
          plannedEndDate: inDays(75),
        },
        {
          ownerId: user.id,
          name: "Extension école Matonge",
          reference: "AK-2026-003",
          clientName: "Fondation Matonge",
          location: "Matonge, Kinshasa",
          status: "planned",
          progress: 12,
          contractAmount: 28000,
          plannedEndDate: inDays(92),
        },
      ],
    });
  }

  console.log(`Seed OK — utilisateur ${email} / demo1234`);
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());