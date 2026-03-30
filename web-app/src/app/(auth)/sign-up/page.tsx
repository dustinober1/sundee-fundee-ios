"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ArtDecoRule } from "@/components/ui/art-deco";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function SignUpPage() {
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  // Handle redirect result after social sign-in (mobile or Apple)
  useEffect(() => {
    async function handleRedirectResult() {
      const { getRedirectResult } = await import("firebase/auth");
      const { getFirebaseAuth } = await import("@/lib/firebase");
      const auth = getFirebaseAuth();

      try {
        const result = await getRedirectResult(auth);
        if (result?.user) {
          // For Apple sign-in, update display name from the ID token
          if (result.providerId === "apple.com") {
            const { updateAppleDisplayName } = await import("@/lib/social-auth");
            await updateAppleDisplayName(result);
          }
          const idToken = await result.user.getIdToken();
          await fetch("/api/auth/session", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ idToken }),
          });
          router.push("/dashboard");
          return;
        }
      } catch (err) {
        const { socialAuthErrorMessage } = await import("@/lib/social-auth");
        setError(socialAuthErrorMessage(err));
        return;
      }

      // Fallback: if Firebase already has a user signed in (redirect result
      // consumed before getRedirectResult ran), sync session and redirect.
      if (auth.currentUser) {
        const idToken = await auth.currentUser.getIdToken();
        await fetch("/api/auth/session", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ idToken }),
        });
        router.push("/dashboard");
      }
    }
    handleRedirectResult();
  }, [router]);

  async function handleEmailSignUp(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const { createUserWithEmailAndPassword, updateProfile } = await import("firebase/auth");
      const { getFirebaseAuth } = await import("@/lib/firebase");
      const auth = getFirebaseAuth();
      const { user } = await createUserWithEmailAndPassword(auth, email, password);
      if (name) await updateProfile(user, { displayName: name });
      router.push("/dashboard");
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === "auth/email-already-in-use") setError("An account with this email already exists");
      else if (code === "auth/weak-password") setError("Password must be at least 6 characters");
      else setError("Something went wrong. Please try again.");
      setLoading(false);
    }
  }

  async function handleGoogleSignIn() {
    setError("");
    try {
      const { signInWithGoogle } = await import("@/lib/social-auth");
      await signInWithGoogle();
      router.push("/dashboard");
    } catch (err) {
      const { socialAuthErrorMessage } = await import("@/lib/social-auth");
      setError(socialAuthErrorMessage(err));
    }
  }

  async function handleAppleSignIn() {
    setError("");
    try {
      const { signInWithApple } = await import("@/lib/social-auth");
      await signInWithApple();
      router.push("/dashboard");
    } catch (err) {
      const { socialAuthErrorMessage } = await import("@/lib/social-auth");
      setError(socialAuthErrorMessage(err));
    }
  }

  return (
    <main className="flex min-h-screen flex-col items-center justify-center px-6">
      <div className="fixed inset-0 pointer-events-none opacity-[0.03]" aria-hidden="true"
        style={{
          backgroundImage: `repeating-linear-gradient(45deg, transparent, transparent 40px, #0d1a40 40px, #0d1a40 41px)`,
        }}
      />
      <div className="relative w-full max-w-sm">
        <Link href="/" className="absolute -top-2 left-0 text-gold font-mono text-[11px] tracking-[0.2em] uppercase hover:text-orange transition-colors">
          &larr; Home
        </Link>
        <div className="text-center mb-10">
          <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-3">Get Started</p>
          <Link href="/" className="hover:opacity-80 transition-opacity">
            <h1 className="!text-4xl !font-bold tracking-tight mb-2">Sundee Fundee</h1>
          </Link>
          <p className="text-text-secondary">Create Your Account</p>
          <ArtDecoRule className="text-gold/30 mt-6" />
        </div>

        {error && (
          <div className="bg-card-bg border-l-[3px] border-l-error text-error rounded-lg px-4 py-3 mb-5 text-sm">{error}</div>
        )}

        <form onSubmit={handleEmailSignUp} className="flex flex-col gap-5">
          <Input label="Name" type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Your name" required />
          <Input label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" required />
          <Input label="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Choose a password (6+ characters)" required minLength={6} />
          <Button type="submit" fullWidth className="!py-3 mt-1 shadow-md shadow-orange/20" disabled={loading}>
            {loading ? "Creating Account..." : "Create Account"}
          </Button>
        </form>

        <div className="relative my-8">
          <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-gold/20" /></div>
          <div className="relative flex justify-center text-[10px]">
            <span className="bg-cream px-3 text-gold font-mono tracking-[0.2em] uppercase">or continue with</span>
          </div>
        </div>

        <div className="flex flex-col gap-3">
          <Button variant="secondary" fullWidth className="!py-3 !border-gold/20 hover:!border-gold/40 transition-colors" onClick={handleGoogleSignIn}>
            Continue with Google
          </Button>
          <Button variant="secondary" fullWidth className="!py-3 !bg-navy !text-cream hover:!opacity-90 transition-opacity" onClick={handleAppleSignIn}>
            Continue with Apple
          </Button>
        </div>

        <p className="text-center text-text-secondary text-[13px] mt-8">
          Already have an account?{" "}
          <Link href="/sign-in" className="text-orange font-semibold hover:underline">Sign In</Link>
        </p>
      </div>
    </main>
  );
}
