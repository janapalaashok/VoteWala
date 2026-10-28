import { defineConfig } from "vitest/config";
import path from "node:path";

export default defineConfig({
  resolve: { alias: { "@": path.resolve(__dirname, "src") } },
  test: {
    environment: "node",
    include: ["tests/**/*.test.ts"],
    fileParallelism: false,
    globalSetup: ["tests/global-setup.ts"],
    env: process.env.TEST_DATABASE_URL
      ? { DATABASE_URL: process.env.TEST_DATABASE_URL, OTP_SECRET: "test-otp-secret", SMS_PROVIDER: "console" }
      : { OTP_SECRET: "test-otp-secret" },
  },
});
