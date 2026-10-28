import type { NextAuthOptions } from "next-auth";
import GoogleProvider from "next-auth/providers/google";
import CredentialsProvider from "next-auth/providers/credentials";
import { PrismaAdapter } from "@next-auth/prisma-adapter";
import { prisma } from "./db";
import { audit } from "./audit";

const adminEmails = () =>
  (process.env.ADMIN_EMAILS ?? "")
    .split(",")
    .map((e) => e.trim().toLowerCase())
    .filter(Boolean);

/** Local-only sign-in for development and end-to-end tests. Never enabled in production. */
export const devLoginEnabled = () =>
  process.env.NODE_ENV !== "production" && process.env.ENABLE_DEV_LOGIN === "true";

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma),
  // JWT sessions keep the cookie stateless; role and verification status are
  // always re-read from the database (see session.ts), never trusted from the token.
  session: { strategy: "jwt", maxAge: 30 * 24 * 60 * 60 },
  pages: { signIn: "/signin" },
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID ?? "",
      clientSecret: process.env.GOOGLE_CLIENT_SECRET ?? "",
    }),
    ...(devLoginEnabled()
      ? [
          CredentialsProvider({
            id: "dev",
            name: "Development login",
            credentials: { email: { label: "Email", type: "email" } },
            async authorize(credentials) {
              const email = credentials?.email?.toLowerCase().trim();
              if (!email) return null;
              const user = await prisma.user.upsert({
                where: { email },
                update: {},
                create: { email, name: email.split("@")[0], emailVerified: new Date() },
              });
              return { id: user.id, email: user.email, name: user.name };
            },
          }),
        ]
      : []),
  ],
  callbacks: {
    async signIn({ account, profile }) {
      // Only accept Google accounts whose email Google has verified.
      if (account?.provider === "google") {
        return Boolean((profile as { email_verified?: boolean } | undefined)?.email_verified);
      }
      return true;
    },
    async jwt({ token, user }) {
      if (user) token.sub = user.id;
      return token;
    },
    async session({ session, token }) {
      if (session.user && token.sub) (session.user as { id?: string }).id = token.sub;
      return session;
    },
  },
  events: {
    async signIn({ user }) {
      if (!user.email) return;
      if (adminEmails().includes(user.email.toLowerCase())) {
        const current = await prisma.user.findUnique({ where: { id: user.id }, select: { role: true } });
        if (current && current.role !== "ADMIN") {
          await prisma.user.update({ where: { id: user.id }, data: { role: "ADMIN" } });
          await audit({ actorId: user.id, action: "user.promoted_admin", entityType: "User", entityId: user.id, metadata: { via: "ADMIN_EMAILS" } });
        }
      }
      await audit({ actorId: user.id, action: "auth.sign_in", entityType: "User", entityId: user.id });
    },
  },
};
