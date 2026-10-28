import { execSync } from "node:child_process";

// Database tests run only when TEST_DATABASE_URL points at a disposable database
// (its name must contain "test"). The schema is recreated and migrated before the run.
export default function setup() {
  const url = process.env.TEST_DATABASE_URL;
  if (!url) return;
  const dbName = new URL(url).pathname.slice(1);
  if (!/test/i.test(dbName)) throw new Error(`Refusing to reset "${dbName}": TEST_DATABASE_URL must name a test database`);
  const env = { ...process.env, DATABASE_URL: url, PRISMA_HIDE_UPDATE_MESSAGE: "1" };
  execSync(`npx prisma db execute --stdin --url "${url}"`, { env, input: "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;", stdio: ["pipe", "ignore", "inherit"] });
  execSync("npx prisma migrate deploy", { env, stdio: ["ignore", "ignore", "inherit"] });
}
