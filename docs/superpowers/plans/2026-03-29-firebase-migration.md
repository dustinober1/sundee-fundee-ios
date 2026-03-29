# Firebase Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate Sundee Fundee from Cloudflare (D1/KV/Workers/Pages) to Firebase (Auth/Firestore/Cloud Functions) + Vercel hosting.

**Architecture:** Vercel hosts the Next.js app. Firebase provides Auth (Google, Apple, email/password), Firestore (NoSQL database), and Cloud Functions (AI workout generation via Vertex AI Gemini Flash). Cloudflare retains DNS only.

**Tech Stack:** Next.js 16, Firebase Client SDK, Firebase Admin SDK, Firestore, Vertex AI, Stripe, Serwist (PWA)

**Spec:** `docs/superpowers/specs/2026-03-29-firebase-migration-design.md`

---

## File Structure

### New files
- `web-app/src/lib/firebase.ts` — Firebase Client SDK initialization
- `web-app/src/lib/firebase-admin.ts` — Firebase Admin SDK initialization (server-side)
- `web-app/src/lib/firestore.ts` — Firestore helper functions (getAuthUser, typed collection refs)
- `web-app/src/components/providers/auth-provider.tsx` — React context for Firebase Auth state
- `firebase/functions/src/index.ts` — Cloud Function entry point (generateWorkout callable)
- `firebase/functions/src/ai.ts` — Vertex AI Gemini integration
- `firebase/functions/src/rate-limit.ts` — Firestore-based rate limiting
- `firebase/functions/package.json` — Cloud Functions dependencies
- `firebase/functions/tsconfig.json` — Cloud Functions TypeScript config
- `firebase.json` — Firebase project config (at repo root)
- `.firebaserc` — Firebase project alias (at repo root)
- `web-app/firestore.rules` — Firestore security rules

### Modified files
- `web-app/src/app/layout.tsx` — Wrap with AuthProvider
- `web-app/src/middleware.ts` — Replace Auth.js with Firebase cookie check
- `web-app/src/app/(auth)/sign-in/page.tsx` — Firebase Auth SDK
- `web-app/src/app/(auth)/sign-up/page.tsx` — Firebase Auth SDK
- `web-app/src/app/(features)/dashboard/page.tsx` — Replace `auth()` with Firebase
- `web-app/src/app/(features)/settings/page.tsx` — Replace `auth()` with Firebase
- `web-app/src/app/(features)/settings/sign-out-button.tsx` — Firebase signOut
- `web-app/src/app/(features)/workouts/actions.ts` — Firestore queries
- `web-app/src/app/(features)/maxes/actions.ts` — Firestore queries
- `web-app/src/app/(features)/cycle/actions.ts` — Firestore queries
- `web-app/src/app/(features)/programs/actions.ts` — Firestore queries
- `web-app/src/app/(features)/benchmarks/actions.ts` — Firestore queries
- `web-app/src/app/(features)/settings/actions.ts` — Firestore queries
- `web-app/src/app/api/stripe/checkout/route.ts` — Firebase auth + env vars
- `web-app/src/app/api/stripe/webhook/route.ts` — Firestore writes
- `web-app/src/app/api/stripe/portal/route.ts` — Firebase auth + Firestore reads
- `web-app/src/app/api/ai/generate/route.ts` — Firebase callable or rewrite
- `web-app/src/lib/stripe.ts` — Remove Cloudflare binding dependency
- `web-app/package.json` — Add firebase deps, remove Cloudflare deps
- `web-app/next.config.ts` — Remove Cloudflare-specific config if any

### Deleted files
- `web-app/src/lib/auth.ts`
- `web-app/src/lib/password.ts`
- `web-app/src/lib/bindings.ts`
- `web-app/src/env.d.ts`
- `web-app/src/db/index.ts`
- `web-app/src/db/schema.ts`
- `web-app/src/app/api/auth/register/route.ts`
- `web-app/src/app/api/auth/[...nextauth]/route.ts`
- `web-app/drizzle/` (entire directory)
- `web-app/drizzle.config.ts`
- `web-app/wrangler.jsonc`
- `web-app/open-next.config.ts`
- `workers/` (entire directory)
- `functions/` (entire directory)

---

## Task 1: Install Dependencies and Configure Firebase Project Files

**Files:**
- Modify: `web-app/package.json`
- Create: `firebase.json`
- Create: `.firebaserc`
- Create: `firebase/functions/package.json`
- Create: `firebase/functions/tsconfig.json`

- [ ] **Step 1: Install Firebase dependencies in web-app**

```bash
cd web-app
npm install firebase firebase-admin @google-cloud/vertexai
npm uninstall @opennextjs/cloudflare @cloudflare/workers-types wrangler drizzle-orm drizzle-kit @auth/drizzle-adapter next-auth
```

- [ ] **Step 2: Create firebase.json at repo root**

```json
{
  "functions": {
    "source": "firebase/functions",
    "runtime": "nodejs20"
  },
  "firestore": {
    "rules": "web-app/firestore.rules"
  }
}
```

- [ ] **Step 3: Create .firebaserc at repo root**

```json
{
  "projects": {
    "default": "sundee-fundee"
  }
}
```

Note: The user will need to run `firebase login` and create the project via `firebase projects:create sundee-fundee` or the Firebase Console. The project ID `sundee-fundee` may need to be adjusted if already taken.

- [ ] **Step 4: Create firebase/functions/package.json**

```json
{
  "name": "sundee-fundee-functions",
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "serve": "npm run build && firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions"
  },
  "engines": {
    "node": "20"
  },
  "dependencies": {
    "firebase-admin": "^13.0.0",
    "firebase-functions": "^6.3.0",
    "@google-cloud/vertexai": "^1.9.0"
  },
  "devDependencies": {
    "typescript": "^5.7.0"
  }
}
```

- [ ] **Step 5: Create firebase/functions/tsconfig.json**

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitReturns": true,
    "noUnusedLocals": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "es2022",
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "compileOnSave": true,
  "include": ["src"]
}
```

- [ ] **Step 6: Install Cloud Functions dependencies**

```bash
cd firebase/functions
npm install
```

- [ ] **Step 7: Remove Cloudflare build scripts from web-app/package.json**

In `web-app/package.json`, remove these scripts:
- `"build:cf"`: `"npx @opennextjs/cloudflare build"`
- `"preview"`: `"npx wrangler dev"`
- `"deploy"`: `"npx @opennextjs/cloudflare deploy"`

Keep `"dev"`, `"build"`, `"start"`, `"postbuild"`, `"lint"`, `"test"`, `"test:watch"`, `"test:coverage"`.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "chore: add Firebase deps, remove Cloudflare deps"
```

---

## Task 2: Create Firebase SDK Initialization Files

**Files:**
- Create: `web-app/src/lib/firebase.ts`
- Create: `web-app/src/lib/firebase-admin.ts`
- Create: `web-app/src/lib/firestore.ts`
- Delete: `web-app/src/lib/bindings.ts`
- Delete: `web-app/src/env.d.ts`

- [ ] **Step 1: Create web-app/src/lib/firebase.ts (Client SDK)**

```typescript
import { initializeApp, getApps } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID,
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

export const firebaseAuth = getAuth(app);
```

- [ ] **Step 2: Create web-app/src/lib/firebase-admin.ts (Admin SDK)**

```typescript
import { initializeApp, getApps, cert, type ServiceAccount } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";

function getAdminApp() {
  if (getApps().length > 0) return getApps()[0];

  return initializeApp({
    credential: cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, "\n"),
    } as ServiceAccount),
  });
}

const adminApp = getAdminApp();

export const adminAuth = getAuth(adminApp);
export const db = getFirestore(adminApp);
```

- [ ] **Step 3: Create web-app/src/lib/firestore.ts (helpers)**

```typescript
import { cookies } from "next/headers";
import { adminAuth, db } from "./firebase-admin";

export interface AuthUser {
  uid: string;
  email: string | undefined;
  name: string | undefined;
}

export async function getAuthUser(): Promise<AuthUser | null> {
  const cookieStore = await cookies();
  const sessionCookie = cookieStore.get("__session")?.value;
  if (!sessionCookie) return null;

  try {
    const decoded = await adminAuth.verifySessionCookie(sessionCookie, true);
    return {
      uid: decoded.uid,
      email: decoded.email,
      name: decoded.name,
    };
  } catch {
    return null;
  }
}

export function userCollection(uid: string, collection: string) {
  return db.collection("users").doc(uid).collection(collection);
}

export function userDoc(uid: string) {
  return db.collection("users").doc(uid);
}

export { db };
```

- [ ] **Step 4: Delete Cloudflare binding files**

```bash
rm web-app/src/lib/bindings.ts
rm web-app/src/env.d.ts
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Firebase SDK initialization and Firestore helpers"
```

---

## Task 3: Create Auth Provider and Session API Route

**Files:**
- Create: `web-app/src/components/providers/auth-provider.tsx`
- Create: `web-app/src/app/api/auth/session/route.ts`
- Modify: `web-app/src/app/layout.tsx`

- [ ] **Step 1: Create the AuthProvider component**

```typescript
"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { onAuthStateChanged, type User } from "firebase/auth";
import { firebaseAuth } from "@/lib/firebase";

interface AuthContextType {
  user: User | null;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType>({ user: null, loading: true });

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(firebaseAuth, async (firebaseUser) => {
      setUser(firebaseUser);
      setLoading(false);

      if (firebaseUser) {
        const idToken = await firebaseUser.getIdToken();
        await fetch("/api/auth/session", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ idToken }),
        });
      } else {
        await fetch("/api/auth/session", { method: "DELETE" });
      }
    });

    return () => unsubscribe();
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading }}>
      {children}
    </AuthContext.Provider>
  );
}
```

- [ ] **Step 2: Create the session API route**

Create `web-app/src/app/api/auth/session/route.ts`:

```typescript
import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { adminAuth } from "@/lib/firebase-admin";

const SESSION_EXPIRY_MS = 60 * 60 * 24 * 5 * 1000; // 5 days

export async function POST(request: Request) {
  const { idToken } = (await request.json()) as { idToken: string };

  try {
    const sessionCookie = await adminAuth.createSessionCookie(idToken, {
      expiresIn: SESSION_EXPIRY_MS,
    });

    const cookieStore = await cookies();
    cookieStore.set("__session", sessionCookie, {
      maxAge: SESSION_EXPIRY_MS / 1000,
      httpOnly: true,
      secure: process.env.NODE_ENV === "production",
      path: "/",
      sameSite: "lax",
    });

    return NextResponse.json({ success: true });
  } catch {
    return NextResponse.json({ error: "Invalid token" }, { status: 401 });
  }
}

export async function DELETE() {
  const cookieStore = await cookies();
  cookieStore.delete("__session");
  return NextResponse.json({ success: true });
}
```

- [ ] **Step 3: Wrap root layout with AuthProvider**

Modify `web-app/src/app/layout.tsx` — add the import and wrap `{children}`:

```typescript
import type { Metadata, Viewport } from "next";
import { Playfair_Display, Inter, JetBrains_Mono } from "next/font/google";
import { AuthProvider } from "@/components/providers/auth-provider";
import "./globals.css";

const playfair = Playfair_Display({
  subsets: ["latin"],
  variable: "--font-heading",
  display: "swap",
});

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-body",
  display: "swap",
});

const jetbrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Sundee Fundee — Strength Training",
  description: "Personalized strength training with hormonal-cycle-aware recommendations.",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Sundee Fundee",
  },
};

export const viewport: Viewport = {
  themeColor: "#0d1a40",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={`${playfair.variable} ${inter.variable} ${jetbrainsMono.variable}`}
    >
      <body>
        <AuthProvider>{children}</AuthProvider>
      </body>
    </html>
  );
}
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "feat: add AuthProvider context and session cookie management"
```

---

## Task 4: Rewrite Auth Pages (Sign In, Sign Up, Sign Out)

**Files:**
- Modify: `web-app/src/app/(auth)/sign-in/page.tsx`
- Modify: `web-app/src/app/(auth)/sign-up/page.tsx`
- Modify: `web-app/src/app/(features)/settings/sign-out-button.tsx`
- Delete: `web-app/src/app/api/auth/register/route.ts`
- Delete: `web-app/src/app/api/auth/[...nextauth]/route.ts`
- Delete: `web-app/src/lib/auth.ts`
- Delete: `web-app/src/lib/password.ts`

- [ ] **Step 1: Rewrite sign-in page**

Replace `web-app/src/app/(auth)/sign-in/page.tsx`:

```typescript
"use client";

import { useState } from "react";
import { signInWithEmailAndPassword, signInWithPopup, GoogleAuthProvider, OAuthProvider } from "firebase/auth";
import { firebaseAuth } from "@/lib/firebase";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function SignInPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function handleEmailSignIn(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      await signInWithEmailAndPassword(firebaseAuth, email, password);
      router.push("/dashboard");
    } catch {
      setError("Invalid email or password");
      setLoading(false);
    }
  }

  async function handleGoogleSignIn() {
    setError("");
    try {
      await signInWithPopup(firebaseAuth, new GoogleAuthProvider());
      router.push("/dashboard");
    } catch {
      setError("Google sign-in failed");
    }
  }

  async function handleAppleSignIn() {
    setError("");
    try {
      const provider = new OAuthProvider("apple.com");
      provider.addScope("email");
      provider.addScope("name");
      await signInWithPopup(firebaseAuth, provider);
      router.push("/dashboard");
    } catch {
      setError("Apple sign-in failed");
    }
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center px-6">
      <div className="fixed inset-0 pointer-events-none opacity-[0.03]" aria-hidden="true"
        style={{
          backgroundImage: `repeating-linear-gradient(
            45deg,
            transparent,
            transparent 40px,
            #0d1a40 40px,
            #0d1a40 41px
          )`,
        }}
      />

      <div className="relative w-full max-w-sm">
        <div className="text-center mb-10">
          <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-3">
            Welcome Back
          </p>
          <h1 className="!text-4xl !font-bold tracking-tight mb-2">Sundee Fundee</h1>
          <p className="text-text-secondary">Strength Training, Your Way</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg px-4 py-3 mb-5 text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleEmailSignIn} className="flex flex-col gap-5">
          <Input
            label="Email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            required
          />
          <Input
            label="Password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Your password"
            required
          />
          <Button type="submit" fullWidth className="!py-3 mt-1" disabled={loading}>
            {loading ? "Signing In..." : "Sign In"}
          </Button>
        </form>

        <div className="relative my-6">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-separator" />
          </div>
          <div className="relative flex justify-center text-xs">
            <span className="bg-cream px-2 text-text-secondary">or continue with</span>
          </div>
        </div>

        <div className="flex flex-col gap-3">
          <Button variant="secondary" fullWidth className="!py-3" onClick={handleGoogleSignIn}>
            Continue with Google
          </Button>
          <Button variant="secondary" fullWidth className="!py-3" onClick={handleAppleSignIn}>
            Continue with Apple
          </Button>
        </div>

        <p className="text-center text-text-secondary text-[13px] mt-8">
          Don&apos;t have an account?{" "}
          <Link href="/sign-up" className="text-orange font-semibold hover:underline">
            Sign Up
          </Link>
        </p>
      </div>
    </main>
  );
}
```

- [ ] **Step 2: Rewrite sign-up page**

Replace `web-app/src/app/(auth)/sign-up/page.tsx`:

```typescript
"use client";

import { useState } from "react";
import { createUserWithEmailAndPassword, updateProfile, signInWithPopup, GoogleAuthProvider, OAuthProvider } from "firebase/auth";
import { firebaseAuth } from "@/lib/firebase";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function SignUpPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  async function handleEmailSignUp(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const { user } = await createUserWithEmailAndPassword(firebaseAuth, email, password);
      if (name) {
        await updateProfile(user, { displayName: name });
      }
      router.push("/dashboard");
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === "auth/email-already-in-use") {
        setError("An account with this email already exists");
      } else if (code === "auth/weak-password") {
        setError("Password must be at least 6 characters");
      } else {
        setError("Something went wrong. Please try again.");
      }
      setLoading(false);
    }
  }

  async function handleGoogleSignIn() {
    setError("");
    try {
      await signInWithPopup(firebaseAuth, new GoogleAuthProvider());
      router.push("/dashboard");
    } catch {
      setError("Google sign-in failed");
    }
  }

  async function handleAppleSignIn() {
    setError("");
    try {
      const provider = new OAuthProvider("apple.com");
      provider.addScope("email");
      provider.addScope("name");
      await signInWithPopup(firebaseAuth, provider);
      router.push("/dashboard");
    } catch {
      setError("Apple sign-in failed");
    }
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center px-6">
      <div className="fixed inset-0 pointer-events-none opacity-[0.03]" aria-hidden="true"
        style={{
          backgroundImage: `repeating-linear-gradient(
            45deg,
            transparent,
            transparent 40px,
            #0d1a40 40px,
            #0d1a40 41px
          )`,
        }}
      />

      <div className="relative w-full max-w-sm">
        <div className="text-center mb-10">
          <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-3">
            Get Started
          </p>
          <h1 className="!text-4xl !font-bold tracking-tight mb-2">Sundee Fundee</h1>
          <p className="text-text-secondary">Create Your Account</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg px-4 py-3 mb-5 text-sm">
            {error}
          </div>
        )}

        <form onSubmit={handleEmailSignUp} className="flex flex-col gap-5">
          <Input
            label="Name"
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Your name"
            required
          />
          <Input
            label="Email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            required
          />
          <Input
            label="Password"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Choose a password (6+ characters)"
            required
            minLength={6}
          />
          <Button type="submit" fullWidth className="!py-3 mt-1" disabled={loading}>
            {loading ? "Creating Account..." : "Create Account"}
          </Button>
        </form>

        <div className="relative my-6">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-separator" />
          </div>
          <div className="relative flex justify-center text-xs">
            <span className="bg-cream px-2 text-text-secondary">or continue with</span>
          </div>
        </div>

        <div className="flex flex-col gap-3">
          <Button variant="secondary" fullWidth className="!py-3" onClick={handleGoogleSignIn}>
            Continue with Google
          </Button>
          <Button variant="secondary" fullWidth className="!py-3" onClick={handleAppleSignIn}>
            Continue with Apple
          </Button>
        </div>

        <p className="text-center text-text-secondary text-[13px] mt-8">
          Already have an account?{" "}
          <Link href="/sign-in" className="text-orange font-semibold hover:underline">
            Sign In
          </Link>
        </p>
      </div>
    </main>
  );
}
```

- [ ] **Step 3: Rewrite sign-out button**

Replace `web-app/src/app/(features)/settings/sign-out-button.tsx`:

```typescript
"use client";

import { signOut } from "firebase/auth";
import { firebaseAuth } from "@/lib/firebase";
import { Button } from "@/components/ui/button";
import { useRouter } from "next/navigation";

export function SignOutButton() {
  const router = useRouter();

  async function handleSignOut() {
    await signOut(firebaseAuth);
    await fetch("/api/auth/session", { method: "DELETE" });
    router.push("/sign-in");
  }

  return (
    <Button variant="secondary" onClick={handleSignOut}>
      Sign Out
    </Button>
  );
}
```

- [ ] **Step 4: Delete old auth files**

```bash
rm web-app/src/lib/auth.ts
rm web-app/src/lib/password.ts
rm web-app/src/app/api/auth/register/route.ts
rm -rf web-app/src/app/api/auth/\[...nextauth\]
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: replace Auth.js with Firebase Auth (email, Google, Apple)"
```

---

## Task 5: Rewrite Middleware for Firebase Session Cookies

**Files:**
- Modify: `web-app/src/middleware.ts`

- [ ] **Step 1: Replace middleware with Firebase cookie check**

Replace `web-app/src/middleware.ts`:

```typescript
import { NextResponse, type NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const sessionCookie = request.cookies.get("__session")?.value;

  if (!sessionCookie) {
    const signInUrl = new URL("/sign-in", request.url);
    return NextResponse.redirect(signInUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/dashboard/:path*",
    "/workouts/:path*",
    "/programs/:path*",
    "/maxes/:path*",
    "/benchmarks/:path*",
    "/cycle/:path*",
    "/settings/:path*",
  ],
};
```

Note: The middleware only checks for cookie presence (fast, no async). The actual token verification happens in server actions/routes via `getAuthUser()`.

- [ ] **Step 2: Commit**

```bash
git add web-app/src/middleware.ts
git commit -m "feat: replace Auth.js middleware with Firebase session cookie check"
```

---

## Task 6: Migrate Server Actions to Firestore

**Files:**
- Modify: `web-app/src/app/(features)/workouts/actions.ts`
- Modify: `web-app/src/app/(features)/maxes/actions.ts`
- Modify: `web-app/src/app/(features)/cycle/actions.ts`
- Modify: `web-app/src/app/(features)/programs/actions.ts`
- Modify: `web-app/src/app/(features)/benchmarks/actions.ts`
- Modify: `web-app/src/app/(features)/settings/actions.ts`

- [ ] **Step 1: Rewrite workouts/actions.ts**

```typescript
"use server";

import { getAuthUser, userCollection, db } from "@/lib/firestore";

export async function getRecentWorkouts() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "completedWorkouts")
    .orderBy("completedAt", "desc")
    .limit(20)
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function saveWorkout(data: {
  programId?: string;
  sessionId?: string;
  durationSeconds: number;
  notes?: string;
  perceivedEffort?: number;
  sets: Array<{
    exerciseName: string;
    setIndex: number;
    prescribedReps: string;
    actualReps?: number;
    prescribedWeightKg?: number;
    actualWeightKg?: number;
    isCompleted: boolean;
  }>;
}) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const workoutRef = userCollection(user.uid, "completedWorkouts").doc();

  await workoutRef.set({
    programId: data.programId ?? "",
    sessionId: data.sessionId ?? "",
    completedAt: new Date(),
    durationSeconds: data.durationSeconds,
    notes: data.notes ?? null,
    perceivedEffort: data.perceivedEffort ?? null,
    sets: data.sets.map((s) => ({
      exerciseName: s.exerciseName,
      setIndex: s.setIndex,
      prescribedReps: s.prescribedReps,
      actualReps: s.actualReps ?? null,
      prescribedWeightKg: s.prescribedWeightKg ?? null,
      actualWeightKg: s.actualWeightKg ?? null,
      isCompleted: s.isCompleted,
      completedAt: new Date(),
    })),
  });

  return { id: workoutRef.id };
}
```

- [ ] **Step 2: Rewrite maxes/actions.ts**

```typescript
"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";

export async function getMaxes() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "oneRepMaxes")
    .orderBy("date", "desc")
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function addMax(data: { exerciseId: string; weightKg: number; isEstimated: boolean }) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  await userCollection(user.uid, "oneRepMaxes").add({
    exerciseId: data.exerciseId,
    weightKg: data.weightKg,
    date: new Date(),
    isEstimated: data.isEstimated,
  });
}
```

- [ ] **Step 3: Rewrite cycle/actions.ts**

```typescript
"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";

export async function getPeriodLogs() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "periodLogs")
    .orderBy("startDate", "desc")
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function getCycleSettings() {
  const user = await getAuthUser();
  if (!user) return null;

  const doc = await userCollection(user.uid, "cycleSettings").doc("default").get();
  return doc.exists ? doc.data() : null;
}

export async function logPeriod(startDate: string) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  await userCollection(user.uid, "periodLogs").add({
    startDate: new Date(startDate),
    flowLevel: "medium",
  });
}
```

- [ ] **Step 4: Rewrite programs/actions.ts**

```typescript
"use server";

import { getAuthUser, userCollection } from "@/lib/firestore";
import { generateProgram, type ProgramTemplate } from "@/lib/domain";

export async function getEnrolledPrograms() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "enrolledPrograms").get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function enrollInProgram(programId: string) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  await userCollection(user.uid, "enrolledPrograms").add({
    programId,
    startDate: new Date(),
    currentWeek: 1,
    currentDay: 1,
    status: "active",
  });
}

export async function generateProgramAction(template: string, name: string) {
  return generateProgram(template as ProgramTemplate, name);
}
```

- [ ] **Step 5: Rewrite benchmarks/actions.ts**

```typescript
"use server";

import { getAuthUser, userCollection, db } from "@/lib/firestore";
import { PREDEFINED_BENCHMARKS } from "@/lib/domain";

export async function getBenchmarkResults() {
  const user = await getAuthUser();
  if (!user) return [];

  const snapshot = await userCollection(user.uid, "benchmarkResults")
    .orderBy("performedAt", "desc")
    .get();

  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

export async function logBenchmarkResult(data: { definitionId: string; scoreValue: number; notes?: string }) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  // Ensure predefined benchmark definition exists
  const predefined = PREDEFINED_BENCHMARKS.find((b) => b.id === data.definitionId);
  if (predefined) {
    const defRef = db.collection("benchmarkDefinitions").doc(predefined.id);
    const defDoc = await defRef.get();
    if (!defDoc.exists) {
      await defRef.set({
        name: predefined.name,
        category: predefined.category,
        workoutDescription: predefined.workoutDescription,
        scoringType: predefined.scoringType,
        isPredefined: true,
        sortOrder: predefined.sortOrder,
      });
    }
  }

  await userCollection(user.uid, "benchmarkResults").add({
    definitionId: data.definitionId,
    scoreValue: data.scoreValue,
    notes: data.notes ?? "",
    performedAt: new Date(),
  });
}
```

- [ ] **Step 6: Rewrite settings/actions.ts**

```typescript
"use server";

import { getAuthUser, userDoc, userCollection } from "@/lib/firestore";

export async function getUserProfile() {
  const user = await getAuthUser();
  if (!user) return null;

  const doc = await userDoc(user.uid).get();
  if (!doc.exists) return null;
  return { id: doc.id, ...doc.data() };
}

export async function updateProfile(data: { name?: string; weightUnit?: string; experienceLevel?: string; primaryGoal?: string }) {
  const user = await getAuthUser();
  if (!user) throw new Error("Unauthorized");

  const updateData: Record<string, unknown> = { profileUpdatedAt: new Date() };
  if (data.name != null) updateData.name = data.name;
  if (data.weightUnit != null) updateData.weightUnit = data.weightUnit;
  if (data.experienceLevel != null) updateData.experienceLevel = data.experienceLevel;
  if (data.primaryGoal != null) updateData.primaryGoal = data.primaryGoal;

  await userDoc(user.uid).set(updateData, { merge: true });
}

export async function getSubscription() {
  const user = await getAuthUser();
  if (!user) return null;

  const doc = await userCollection(user.uid, "subscription").doc("current").get();
  return doc.exists ? doc.data() : null;
}
```

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: migrate all server actions from Drizzle/D1 to Firestore"
```

---

## Task 7: Migrate Dashboard and Settings Pages

**Files:**
- Modify: `web-app/src/app/(features)/dashboard/page.tsx`
- Modify: `web-app/src/app/(features)/settings/page.tsx`

- [ ] **Step 1: Rewrite dashboard page**

Replace `web-app/src/app/(features)/dashboard/page.tsx`:

```typescript
import { getAuthUser } from "@/lib/firestore";
import { Card } from "@/components/ui/card";
import Link from "next/link";
import { redirect } from "next/navigation";

export default async function DashboardPage() {
  const user = await getAuthUser();
  if (!user) redirect("/sign-in");

  const userName = user.name ?? "Athlete";
  const today = new Date().toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  return (
    <div className="flex flex-col gap-spacing-md">
      <div>
        <h1 className="text-3xl">Hey, {userName}</h1>
        <p className="text-text-secondary">{today}</p>
      </div>

      <div className="grid grid-cols-3 gap-spacing-sm">
        <Card className="text-center">
          <p className="text-2xl font-bold text-orange">0</p>
          <p className="text-[11px] text-text-secondary">This Week</p>
        </Card>
        <Card className="text-center">
          <p className="text-2xl font-bold text-orange">0</p>
          <p className="text-[11px] text-text-secondary">Day Streak</p>
        </Card>
        <Card className="text-center">
          <p className="text-2xl font-bold text-orange">—</p>
          <p className="text-[11px] text-text-secondary">Program</p>
        </Card>
      </div>

      <Card>
        <h2 className="mb-spacing-sm">Quick Actions</h2>
        <div className="grid grid-cols-2 gap-spacing-sm">
          <Link
            href="/workouts"
            className="flex items-center justify-center gap-2 bg-orange text-cream rounded-button py-spacing-sm px-spacing-md text-[14px] font-medium hover:opacity-90"
          >
            Start Workout
          </Link>
          <Link
            href="/maxes"
            className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-navy rounded-button py-spacing-sm px-spacing-md text-[14px] font-medium hover:bg-separator/30"
          >
            Log Max
          </Link>
          <Link
            href="/programs"
            className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-navy rounded-button py-spacing-sm px-spacing-md text-[14px] font-medium hover:bg-separator/30"
          >
            Programs
          </Link>
          <Link
            href="/benchmarks"
            className="flex items-center justify-center gap-2 bg-card-bg text-navy border border-navy rounded-button py-spacing-sm px-spacing-md text-[14px] font-medium hover:bg-separator/30"
          >
            Benchmarks
          </Link>
        </div>
      </Card>

      <Card>
        <h2 className="mb-spacing-sm">Recent Activity</h2>
        <p className="text-text-secondary text-[13px]">
          No workouts yet. Start your first workout to see activity here.
        </p>
      </Card>
    </div>
  );
}
```

- [ ] **Step 2: Rewrite settings page**

Replace `web-app/src/app/(features)/settings/page.tsx`:

```typescript
import { Card } from "@/components/ui/card";
import { getAuthUser } from "@/lib/firestore";
import { getUserProfile, getSubscription } from "./actions";
import { tierDisplayName } from "@/lib/domain";
import { ProfileForm } from "./profile-form";
import { SubscriptionCard } from "./subscription-card";
import { SignOutButton } from "./sign-out-button";
import { redirect } from "next/navigation";

export default async function SettingsPage() {
  const [user, profile, subscription] = await Promise.all([
    getAuthUser(),
    getUserProfile(),
    getSubscription(),
  ]);

  if (!user) redirect("/sign-in");

  const tier = ((subscription as Record<string, unknown>)?.tier as "free" | "plus" | "premium") ?? "free";

  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Settings</h1>

      <Card>
        <h2 className="mb-spacing-sm">Profile</h2>
        <ProfileForm
          initialName={(profile as Record<string, unknown>)?.name as string ?? user.name ?? ""}
          initialWeightUnit={(profile as Record<string, unknown>)?.weightUnit as string ?? "lb"}
          initialExperience={(profile as Record<string, unknown>)?.experienceLevel as string ?? "beginner"}
          initialGoal={(profile as Record<string, unknown>)?.primaryGoal as string ?? "strength"}
        />
      </Card>

      <SubscriptionCard tier={tier} />

      <Card>
        <h2 className="mb-spacing-sm">Account</h2>
        <p className="text-text-secondary text-[13px] mb-spacing-sm">{user.email}</p>
        <SignOutButton />
      </Card>
    </div>
  );
}
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: migrate dashboard and settings pages to Firebase"
```

---

## Task 8: Migrate Stripe API Routes

**Files:**
- Modify: `web-app/src/app/api/stripe/checkout/route.ts`
- Modify: `web-app/src/app/api/stripe/webhook/route.ts`
- Modify: `web-app/src/app/api/stripe/portal/route.ts`
- Modify: `web-app/src/lib/stripe.ts`

- [ ] **Step 1: Update stripe.ts to use env vars directly**

Replace `web-app/src/lib/stripe.ts`:

```typescript
import Stripe from "stripe";

export const STRIPE_PRICES = {
  plus: {
    monthly: "price_1TGMEmR3qTJLE6bbfrsZYIJt",
    annual: "price_1TGMEmR3qTJLE6bb2d7Xkocg",
  },
  premium: {
    monthly: "price_1TGMEnR3qTJLE6bbeooKfY0E",
    annual: "price_1TGMEoR3qTJLE6bbMW01HMya",
  },
} as const;

export function tierFromPriceId(priceId: string): "plus" | "premium" | null {
  for (const [tier, prices] of Object.entries(STRIPE_PRICES)) {
    if (prices.monthly === priceId || prices.annual === priceId) {
      return tier as "plus" | "premium";
    }
  }
  return null;
}

export function createStripeClient(): Stripe {
  return new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: "2026-03-25.dahlia" });
}
```

- [ ] **Step 2: Rewrite checkout route**

Replace `web-app/src/app/api/stripe/checkout/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { getAuthUser } from "@/lib/firestore";
import { createStripeClient, STRIPE_PRICES } from "@/lib/stripe";

export async function POST(req: NextRequest) {
  const user = await getAuthUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json();
  const { tier, interval } = body as {
    tier: "plus" | "premium";
    interval: "monthly" | "annual";
  };

  if (!tier || !interval || !STRIPE_PRICES[tier]?.[interval]) {
    return NextResponse.json({ error: "Invalid tier or interval" }, { status: 400 });
  }

  const stripe = createStripeClient();
  const appUrl = process.env.NEXT_PUBLIC_APP_URL!;

  const checkoutSession = await stripe.checkout.sessions.create({
    mode: "subscription",
    customer_email: user.email ?? undefined,
    line_items: [{ price: STRIPE_PRICES[tier][interval], quantity: 1 }],
    allow_promotion_codes: true,
    success_url: `${appUrl}/settings?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${appUrl}/settings`,
    metadata: { userId: user.uid },
  });

  return NextResponse.json({ url: checkoutSession.url });
}
```

- [ ] **Step 3: Rewrite webhook route**

Replace `web-app/src/app/api/stripe/webhook/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { createStripeClient, tierFromPriceId } from "@/lib/stripe";
import { db } from "@/lib/firebase-admin";

export async function POST(req: NextRequest) {
  const stripe = createStripeClient();
  const body = await req.text();
  const sig = req.headers.get("stripe-signature")!;

  let event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch {
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  switch (event.type) {
    case "checkout.session.completed": {
      const session = event.data.object;
      const userId = session.metadata?.userId;
      if (!userId || !session.subscription) break;

      const sub = await stripe.subscriptions.retrieve(session.subscription as string);
      const item = sub.items.data[0];
      const priceId = item?.price.id;
      const tier = tierFromPriceId(priceId ?? "") ?? "free";
      const periodEnd = item?.current_period_end ?? 0;

      await db.collection("users").doc(userId).collection("subscription").doc("current").set({
        stripeCustomerId: session.customer as string,
        stripeSubscriptionId: session.subscription as string,
        tier,
        status: "active",
        currentPeriodEnd: new Date(periodEnd * 1000),
        createdAt: new Date(),
        updatedAt: new Date(),
      }, { merge: true });
      break;
    }

    case "customer.subscription.updated":
    case "customer.subscription.deleted": {
      const sub = event.data.object;
      const item = sub.items.data[0];
      const priceId = item?.price.id;
      const periodEnd = item?.current_period_end ?? 0;
      const tier = sub.status === "active" ? (tierFromPriceId(priceId ?? "") ?? "free") : "free";

      // Find user by stripeSubscriptionId
      const usersSnapshot = await db.collectionGroup("subscription")
        .where("stripeSubscriptionId", "==", sub.id)
        .limit(1)
        .get();

      if (!usersSnapshot.empty) {
        await usersSnapshot.docs[0].ref.update({
          tier,
          status: sub.status === "active" ? "active" : "canceled",
          currentPeriodEnd: new Date(periodEnd * 1000),
          updatedAt: new Date(),
        });
      }
      break;
    }
  }

  return NextResponse.json({ received: true });
}
```

- [ ] **Step 4: Rewrite portal route**

Replace `web-app/src/app/api/stripe/portal/route.ts`:

```typescript
import { NextResponse } from "next/server";
import { getAuthUser } from "@/lib/firestore";
import { createStripeClient } from "@/lib/stripe";
import { db } from "@/lib/firebase-admin";

export async function POST() {
  const user = await getAuthUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const subDoc = await db.collection("users").doc(user.uid)
    .collection("subscription").doc("current").get();

  const stripeCustomerId = subDoc.data()?.stripeCustomerId;
  if (!stripeCustomerId) {
    return NextResponse.json({ error: "No subscription found" }, { status: 404 });
  }

  const stripe = createStripeClient();
  const portalSession = await stripe.billingPortal.sessions.create({
    customer: stripeCustomerId,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/settings`,
  });

  return NextResponse.json({ url: portalSession.url });
}
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat: migrate Stripe routes from D1 to Firestore"
```

---

## Task 9: Create Cloud Function for AI Workout Generation

**Files:**
- Create: `firebase/functions/src/index.ts`
- Create: `firebase/functions/src/ai.ts`
- Create: `firebase/functions/src/rate-limit.ts`
- Modify: `web-app/src/app/api/ai/generate/route.ts`

- [ ] **Step 1: Create firebase/functions/src/rate-limit.ts**

```typescript
import { getFirestore } from "firebase-admin/firestore";

const TIER_LIMITS: Record<string, number> = {
  plus: 1,
  premium: 10,
};

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetsAt?: string;
}

export async function checkRateLimit(userId: string, tier: string): Promise<RateLimitResult> {
  const db = getFirestore();
  const today = new Date().toISOString().split("T")[0];
  const limit = TIER_LIMITS[tier] ?? 0;

  if (limit === 0) {
    return { allowed: false, remaining: 0 };
  }

  const usageRef = db.collection("users").doc(userId).collection("aiUsage").doc(today);
  const usageDoc = await usageRef.get();
  const current = (usageDoc.data()?.count as number) ?? 0;

  if (current >= limit) {
    const tomorrow = new Date();
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
    tomorrow.setUTCHours(0, 0, 0, 0);
    return { allowed: false, remaining: 0, resetsAt: tomorrow.toISOString() };
  }

  await usageRef.set({ count: current + 1, updatedAt: new Date() }, { merge: true });
  return { allowed: true, remaining: limit - current - 1 };
}
```

- [ ] **Step 2: Create firebase/functions/src/ai.ts**

```typescript
import { VertexAI } from "@google-cloud/vertexai";

export interface Exercise {
  name: string;
  sets: number;
  reps: string;
  weightKg: number | null;
  restMinutes: number | null;
  notes: string | null;
  bodyweightOnly: boolean;
}

export interface WorkoutResponse {
  coachingSummary: string;
  exercises: Exercise[];
}

export async function generateWorkout(
  projectId: string,
  prompt: string,
  systemInstruction: string,
): Promise<WorkoutResponse> {
  const vertexAI = new VertexAI({ project: projectId, location: "us-central1" });
  const model = vertexAI.getGenerativeModel({ model: "gemini-2.0-flash" });

  const result = await model.generateContent({
    systemInstruction: { role: "system", parts: [{ text: systemInstruction }] },
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: {
      responseMimeType: "application/json",
    },
  });

  const raw = result.response.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!raw) {
    throw new Error("No response from AI model");
  }

  const cleaned = stripMarkdownFences(raw);

  let parsed: unknown;
  try {
    parsed = JSON.parse(cleaned);
  } catch {
    throw new Error("Failed to parse AI response as JSON");
  }

  if (!isValidWorkoutResponse(parsed)) {
    throw new Error("Invalid response structure from AI");
  }

  return parsed;
}

function stripMarkdownFences(text: string): string {
  const trimmed = text.trim();
  if (trimmed.startsWith("```")) {
    const lines = trimmed.split("\n");
    lines.shift();
    if (lines[lines.length - 1]?.trim() === "```") {
      lines.pop();
    }
    return lines.join("\n");
  }
  return trimmed;
}

function isValidWorkoutResponse(data: unknown): data is WorkoutResponse {
  if (typeof data !== "object" || data === null) return false;
  const obj = data as Record<string, unknown>;
  return typeof obj.coachingSummary === "string" && Array.isArray(obj.exercises);
}
```

- [ ] **Step 3: Create firebase/functions/src/index.ts**

```typescript
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { checkRateLimit } from "./rate-limit";
import { generateWorkout } from "./ai";

initializeApp();

export const generateWorkoutFn = onCall(
  { region: "us-central1", memory: "512MiB", timeoutSeconds: 120 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be signed in");
    }

    const userId = request.auth.uid;
    const { prompt, systemInstruction } = request.data as {
      prompt?: string;
      systemInstruction?: string;
    };

    if (!prompt || !systemInstruction) {
      throw new HttpsError("invalid-argument", "Missing prompt or systemInstruction");
    }

    // Check subscription tier
    const db = getFirestore();
    const subDoc = await db.collection("users").doc(userId)
      .collection("subscription").doc("current").get();
    const tier = (subDoc.data()?.tier as string) ?? "free";

    if (tier === "free") {
      throw new HttpsError("permission-denied", "Cloud AI requires a Plus or Premium subscription");
    }

    // Rate limit
    const rateResult = await checkRateLimit(userId, tier);
    if (!rateResult.allowed) {
      throw new HttpsError("resource-exhausted", "Daily limit exceeded", {
        remaining: 0,
        resetsAt: rateResult.resetsAt,
      });
    }

    // Generate
    const projectId = process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT ?? "";
    const workout = await generateWorkout(projectId, prompt, systemInstruction);

    // Save record
    await db.collection("users").doc(userId).collection("generatedWorkoutRecords").add({
      prompt,
      response: JSON.stringify(workout),
      createdAt: new Date(),
    });

    return workout;
  },
);
```

- [ ] **Step 4: Rewrite the AI generate API route to call Cloud Function logic directly**

The API route runs server-side on Vercel with admin credentials. Instead of calling the Cloud Function via HTTP (which adds complexity with service-to-service auth), we replicate the same logic inline — check subscription, rate limit, call Vertex AI. The Cloud Function (`generateWorkoutFn`) exists for direct client calls via `httpsCallable()` if needed later.

Replace `web-app/src/app/api/ai/generate/route.ts`:

```typescript
import { NextRequest, NextResponse } from "next/server";
import { getAuthUser, userCollection } from "@/lib/firestore";
import { db } from "@/lib/firebase-admin";

export async function POST(req: NextRequest) {
  const user = await getAuthUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = (await req.json()) as { prompt?: string; systemInstruction?: string };
  if (!body.prompt || !body.systemInstruction) {
    return NextResponse.json({ error: "Missing prompt or systemInstruction" }, { status: 400 });
  }

  // Check subscription tier
  const subDoc = await db.collection("users").doc(user.uid)
    .collection("subscription").doc("current").get();
  const tier = (subDoc.data()?.tier as string) ?? "free";

  if (tier === "free") {
    return NextResponse.json({ error: "Cloud AI requires a Plus or Premium subscription" }, { status: 403 });
  }

  // Rate limit
  const tierLimits: Record<string, number> = { plus: 1, premium: 10 };
  const limit = tierLimits[tier] ?? 0;
  const today = new Date().toISOString().split("T")[0];
  const usageRef = db.collection("users").doc(user.uid).collection("aiUsage").doc(today);
  const usageDoc = await usageRef.get();
  const current = (usageDoc.data()?.count as number) ?? 0;

  if (current >= limit) {
    return NextResponse.json({ error: "Daily limit exceeded" }, { status: 429 });
  }

  try {
    // Dynamic import to avoid bundling Vertex AI in non-AI routes
    const { VertexAI } = await import("@google-cloud/vertexai");
    const vertexAI = new VertexAI({
      project: process.env.FIREBASE_PROJECT_ID!,
      location: "us-central1",
    });
    const model = vertexAI.getGenerativeModel({ model: "gemini-2.0-flash" });

    const result = await model.generateContent({
      systemInstruction: { role: "system", parts: [{ text: body.systemInstruction }] },
      contents: [{ role: "user", parts: [{ text: body.prompt }] }],
      generationConfig: { responseMimeType: "application/json" },
    });

    const raw = result.response.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!raw) {
      return NextResponse.json({ error: "No response from AI" }, { status: 502 });
    }

    const workout = JSON.parse(raw);

    // Increment usage
    await usageRef.set({ count: current + 1, updatedAt: new Date() }, { merge: true });

    // Save record
    await userCollection(user.uid, "generatedWorkoutRecords").add({
      prompt: body.prompt,
      response: JSON.stringify(workout),
      createdAt: new Date(),
    });

    return NextResponse.json(workout);
  } catch {
    return NextResponse.json({ error: "AI generation failed" }, { status: 500 });
  }
}
```

- [ ] **Step 5: Commit**

```bash
cd firebase/functions && npm install
git add -A
git commit -m "feat: add Cloud Function for AI workout generation via Vertex AI"
```

---

## Task 10: Delete Cloudflare and Legacy Files

**Files:**
- Delete: `web-app/wrangler.jsonc`
- Delete: `web-app/open-next.config.ts`
- Delete: `web-app/drizzle.config.ts`
- Delete: `web-app/drizzle/` (directory)
- Delete: `web-app/src/db/` (directory)
- Delete: `workers/` (directory)
- Delete: `functions/` (directory)

- [ ] **Step 1: Delete all Cloudflare-specific files**

```bash
rm -f web-app/wrangler.jsonc
rm -f web-app/open-next.config.ts
rm -f web-app/drizzle.config.ts
rm -rf web-app/drizzle
rm -rf web-app/src/db
```

- [ ] **Step 2: Delete Cloudflare AI Worker**

```bash
rm -rf workers
```

- [ ] **Step 3: Delete legacy Firebase Functions**

```bash
rm -rf functions
```

- [ ] **Step 4: Verify no dangling imports**

```bash
cd web-app && npx tsc --noEmit
```

Fix any import errors that reference deleted modules (`@/db`, `@/lib/bindings`, `@/lib/auth`, `drizzle-orm`).

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore: remove Cloudflare, Drizzle, and legacy Firebase files"
```

---

## Task 11: Create Firestore Security Rules

**Files:**
- Create: `web-app/firestore.rules`

- [ ] **Step 1: Write security rules**

Create `web-app/firestore.rules`:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // User profile document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // All user subcollections
      match /{subcollection}/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Shared benchmark definitions (read by all authenticated, write by admin/server only)
    match /benchmarkDefinitions/{docId} {
      allow read: if request.auth != null;
      allow write: if false; // Server-side only via Admin SDK
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add web-app/firestore.rules
git commit -m "feat: add Firestore security rules"
```

---

## Task 12: Update CLAUDE.md and Verify Build

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Run TypeScript check**

```bash
cd web-app && npx tsc --noEmit
```

Fix any remaining type errors.

- [ ] **Step 2: Run tests**

```bash
cd web-app && npm test
```

All domain tests should pass unchanged since `src/lib/domain/` has no infrastructure dependencies.

- [ ] **Step 3: Run lint**

```bash
cd web-app && npm run lint
```

- [ ] **Step 4: Update CLAUDE.md**

Update the CLAUDE.md to reflect the new Firebase architecture. Key changes:
- Architecture diagram: Vercel + Firebase instead of Cloudflare
- Database section: Firestore instead of D1/Drizzle
- Auth section: Firebase Auth instead of Auth.js
- AI section: Cloud Functions + Vertex AI instead of Cloudflare Worker
- Environment variables: Firebase config instead of Cloudflare bindings
- Commands: Remove Cloudflare-specific commands, add Firebase commands
- Remove references to `wrangler`, `drizzle-kit`, `@opennextjs/cloudflare`
- Remove `src/db/schema.ts`, `src/lib/bindings.ts`, `src/lib/auth.ts` references
- Add `src/lib/firebase.ts`, `src/lib/firebase-admin.ts`, `src/lib/firestore.ts` references
- Add `firebase/functions/` directory description

- [ ] **Step 5: Run build**

```bash
cd web-app && npm run build
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "chore: update CLAUDE.md for Firebase migration, verify build passes"
```

---

## Task 13: Deployment Setup

This task is manual setup — not code changes.

- [ ] **Step 1: Create Firebase project**

```bash
firebase login
firebase projects:create sundee-fundee
firebase use sundee-fundee
```

Enable in Firebase Console:
- Authentication (Email/Password, Google, Apple providers)
- Cloud Firestore
- Cloud Functions (requires Blaze plan for external network access)

- [ ] **Step 2: Get Firebase config values**

From Firebase Console → Project Settings → General → Web App → Add Web App:
- Copy `apiKey`, `authDomain`, `projectId`

From Firebase Console → Project Settings → Service Accounts → Generate New Private Key:
- Copy `project_id`, `client_email`, `private_key`

- [ ] **Step 3: Connect Vercel**

1. Import GitHub repo in Vercel dashboard
2. Set root directory to `web-app`
3. Framework preset: Next.js
4. Add environment variables:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_CLIENT_EMAIL`
   - `FIREBASE_PRIVATE_KEY`
   - `NEXT_PUBLIC_FIREBASE_API_KEY`
   - `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN`
   - `NEXT_PUBLIC_FIREBASE_PROJECT_ID`
   - `STRIPE_SECRET_KEY`
   - `STRIPE_WEBHOOK_SECRET`
   - `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY`
   - `NEXT_PUBLIC_APP_URL`

- [ ] **Step 4: Deploy Cloud Functions**

```bash
cd firebase/functions
npm run build
firebase deploy --only functions
```

- [ ] **Step 5: Deploy Firestore rules**

```bash
firebase deploy --only firestore:rules
```

- [ ] **Step 6: Update Cloudflare DNS**

In Cloudflare dashboard:
- Change DNS records to point `sundeefundee.com` to Vercel (CNAME `cname.vercel-dns.com`)
- Remove any Cloudflare Pages project
- Delete D1 database, KV namespace, and AI Worker

- [ ] **Step 7: Update Stripe webhook endpoint**

In Stripe Dashboard → Developers → Webhooks:
- Update endpoint URL to `https://sundeefundee.com/api/stripe/webhook`
- Get new webhook signing secret and update Vercel env var `STRIPE_WEBHOOK_SECRET`

- [ ] **Step 8: Test end-to-end**

1. Visit `https://sundeefundee.com/sign-up`
2. Create account with email/password
3. Sign out and sign in with Google
4. Navigate protected routes
5. Check that all pages load without errors
