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
          backgroundImage: `repeating-linear-gradient(45deg, transparent, transparent 40px, #0d1a40 40px, #0d1a40 41px)`,
        }}
      />
      <div className="relative w-full max-w-sm">
        <div className="text-center mb-10">
          <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-3">Welcome Back</p>
          <h1 className="!text-4xl !font-bold tracking-tight mb-2">Sundee Fundee</h1>
          <p className="text-text-secondary">Strength Training, Your Way</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg px-4 py-3 mb-5 text-sm">{error}</div>
        )}

        <form onSubmit={handleEmailSignIn} className="flex flex-col gap-5">
          <Input label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" required />
          <Input label="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Your password" required />
          <Button type="submit" fullWidth className="!py-3 mt-1" disabled={loading}>
            {loading ? "Signing In..." : "Sign In"}
          </Button>
        </form>

        <div className="relative my-6">
          <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-separator" /></div>
          <div className="relative flex justify-center text-xs"><span className="bg-cream px-2 text-text-secondary">or continue with</span></div>
        </div>

        <div className="flex flex-col gap-3">
          <Button variant="secondary" fullWidth className="!py-3" onClick={handleGoogleSignIn}>Continue with Google</Button>
          <Button variant="secondary" fullWidth className="!py-3" onClick={handleAppleSignIn}>Continue with Apple</Button>
        </div>

        <p className="text-center text-text-secondary text-[13px] mt-8">
          Don&apos;t have an account?{" "}
          <Link href="/sign-up" className="text-orange font-semibold hover:underline">Sign Up</Link>
        </p>
      </div>
    </main>
  );
}
