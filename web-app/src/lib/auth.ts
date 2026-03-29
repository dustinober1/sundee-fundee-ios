import NextAuth from "next-auth";
import Google from "next-auth/providers/google";
import Apple from "next-auth/providers/apple";
import Credentials from "next-auth/providers/credentials";
import { DrizzleAdapter } from "@auth/drizzle-adapter";
import { createDb } from "@/db";
import { getBindings } from "@/lib/bindings";

export const { handlers, signIn, signOut, auth } = NextAuth(async () => {
  const env = await getBindings();
  const db = createDb(env.DB);

  return {
    adapter: DrizzleAdapter(db),
    providers: [
      Google({
        clientId: env.AUTH_GOOGLE_ID,
        clientSecret: env.AUTH_GOOGLE_SECRET,
      }),
      Apple({
        clientId: env.AUTH_APPLE_ID,
        clientSecret: env.AUTH_APPLE_SECRET,
      }),
      Credentials({
        name: "Email",
        credentials: {
          email: { label: "Email", type: "email" },
          password: { label: "Password", type: "password" },
        },
        async authorize() {
          return null;
        },
      }),
    ],
    session: { strategy: "jwt" },
    pages: { signIn: "/sign-in" },
    callbacks: {
      jwt({ token, user }) {
        if (user) token.id = user.id;
        return token;
      },
      session({ session, token }) {
        if (token.id) session.user.id = token.id as string;
        return session;
      },
    },
  };
});
