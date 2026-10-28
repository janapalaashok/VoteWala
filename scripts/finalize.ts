// Freezes end-of-day reports for all closed polls. Safe to run repeatedly.
//   npm run finalize
import { finalizeClosedPolls } from "../src/lib/finalize";
import { prisma } from "../src/lib/db";

finalizeClosedPolls()
  .then((ids) => console.log(`✔ Finalized ${ids.length} poll(s)`))
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
