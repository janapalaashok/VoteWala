// Promotes an existing user (who has signed in at least once) to ADMIN.
//   npm run make-admin -- someone@example.com
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
const email = process.argv[2]?.toLowerCase().trim();

async function main() {
  if (!email) throw new Error("Usage: npm run make-admin -- <email>");
  const user = await prisma.user.update({ where: { email }, data: { role: "ADMIN" } });
  await prisma.auditLog.create({ data: { actorId: null, action: "user.promoted_admin", entityType: "User", entityId: user.id, metadata: { via: "cli" } } });
  console.log(`✔ ${email} is now an admin`);
}

main()
  .catch((e) => {
    console.error(e.message);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
