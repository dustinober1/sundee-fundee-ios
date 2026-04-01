"use client";

import { useState, useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { ArtDecoRule } from "@/components/ui/art-deco";
import Link from "next/link";
import { useRouter } from "next/navigation";

export default function SignInPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();

  // Handle redirect result after social sign-in (mobile or Apple)
  useEffect(() => {
    async function handleRedirectResult() {
      const { completeSocialRedirect } = await import("@/lib/complete-social-redirect");
      const completion = await completeSocialRedirect();

      if (completion.status === "success") {
        router.push("/dashboard");
        return;
      }

      if (completion.status === "error") {
        setError(completion.message);
      }
    }

    handleRedirectResult();
  }, [router]);

  async function handleEmailSignIn(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const { signInWithEmailAndPassword } = await import("firebase/auth");
      const { getFirebaseAuth } = await import("@/lib/firebase");
      const auth = getFirebaseAuth();
      await signInWithEmailAndPassword(auth, email, password);
      router.push("/dashboard");
    } catch {
      setError("Invalid email or password");
      setLoading(false);
    }
  }

  async function handleGoogleSignIn() {
    setError("");
    setLoading(true);
    try {
      const { signInWithGoogle } = await import("@/lib/social-auth");
      await signInWithGoogle();
      router.replace("/dashboard");
      router.refresh();
    } catch (err) {
      const { socialAuthErrorMessage } = await import("@/lib/social-auth");
      setError(socialAuthErrorMessage(err));
      setLoading(false);
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
          <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-3">Welcome Back</p>
          <Link href="/" className="hover:opacity-80 transition-opacity">
            <h1 className="!text-4xl !font-bold tracking-tight mb-2">Sundee Fundee</h1>
          </Link>
          <p className="text-text-secondary">Strength Training, Your Way</p>
          <ArtDecoRule className="text-gold/30 mt-6" />
        </div>

        {error && (
          <div className="bg-card-bg border-l-[3px] border-l-error text-error rounded-lg px-4 py-3 mb-5 text-sm">{error}</div>
        )}

        <form onSubmit={handleEmailSignIn} className="flex flex-col gap-5">
          <Input label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" required />
          <Input label="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Your password" required />
          <Button type="submit" fullWidth className="!py-3 mt-1 shadow-md shadow-orange/20" disabled={loading}>
            {loading ? "Signing In..." : "Sign In"}
          </Button>
        </form>

        <div className="relative my-8">
          <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-gold/20" /></div>
          <div className="relative flex justify-center text-[10px]">
            <span className="bg-cream px-3 text-gold font-mono tracking-[0.2em] uppercase">or continue with</span>
          </div>
        </div>

        <div className="flex flex-col gap-3">
          <Button type="button" variant="secondary" fullWidth className="!py-3 !border-gold/20 hover:!border-gold/40 transition-colors" onClick={handleGoogleSignIn} disabled={loading}>
            Continue with Google
          </Button>
        </div>

        <p className="text-center text-text-secondary text-[13px] mt-8">
          Don&apos;t have an account?{" "}
          <Link href="/sign-up" className="text-orange font-semibold hover:underline">Sign Up</Link>
        </p>
      </div>
    </main>
  );
}
