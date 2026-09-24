import { PrismaClient } from "@prisma/client";

let client: PrismaClient | undefined;

/** Instance partagée (lazy) pour rester léger dans les tests. */
export function prisma(): PrismaClient {
  client ??= new PrismaClient();
  return client;
}
