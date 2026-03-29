"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import Link from "next/link";
import { useRouter } from "next/navigation";

async function getAuth() {
  const { getFirebaseAuth } = await import("@/lib/firebase");
  return getFirebaseAuth();
}

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
      const { createUserWithEmailAndPassword, updateProfile } = await import("firebase/auth");
      const auth = await getAuth();
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
      const { signInWithPopup, GoogleAuthProvider } = await import("firebase/auth");
      const auth = await getAuth();
      await signInWithPopup(auth, new GoogleAuthProvider());
      router.push("/dashboard");
    } catch {
      setError("Google sign-in failed");
    }
  }

  async function handleAppleSignIn() {
    setError("");
    try {
      const { signInWithPopup, OAuthProvider } = await import("firebase/auth");
      const auth = await getAuth();
      const provider = new OAuthProvider("apple.com");
      provider.addScope("email");
      provider.addScope("name");
      await signInWithPopup(auth, provider);
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
          <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-3">Get Started</p>
          <h1 className="!text-4xl !font-bold tracking-tight mb-2">Sundee Fundee</h1>
          <p className="text-text-secondary">Create Your Account</p>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 rounded-lg px-4 py-3 mb-5 text-sm">{error}</div>
        )}

        <form onSubmit={handleEmailSignUp} className="flex flex-col gap-5">
          <Input label="Name" type="text" value={name} onChange={(e) => setName(e.target.value)} placeholder="Your name" required />
          <Input label="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" required />
          <Input label="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="Choose a password (6+ characters)" required minLength={6} />
          <Button type="submit" fullWidth className="!py-3 mt-1" disabled={loading}>
            {loading ? "Creating Account..." : "Create Account"}
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
          Already have an account?{" "}
          <Link href="/sign-in" className="text-orange font-semibold hover:underline">Sign In</Link>
        </p>
      </div>
    </main>
  );
}
