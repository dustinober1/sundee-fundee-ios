"use client";

import { useSearchParams } from "next/navigation";
import { Suspense } from "react";
import { Button } from "@/components/ui/button";
import { ArtDecoRule } from "@/components/ui/art-deco";
import Link from "next/link";

const errorMessages: Record<string, string> = {
  Configuration: "There is a problem with the server configuration. Please try again later.",
  AccessDenied: "Access was denied. You may not have permission to sign in.",
  Verification: "The verification link has expired or has already been used.",
  Default: "An unexpected error occurred. Please try again.",
};

function AuthErrorContent() {
  const searchParams = useSearchParams();
  const error = searchParams.get("error") ?? "Default";
  const message = errorMessages[error] ?? errorMessages.Default;

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

      <div className="relative w-full max-w-sm text-center">
        <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-3">
          Sign-In Error
        </p>
        <h1 className="!text-3xl !font-bold tracking-tight mb-4">
          Something Went Wrong
        </h1>
        <ArtDecoRule className="text-gold/30 mb-6" />
        <div className="bg-card-bg border-l-[3px] border-l-error rounded-lg px-5 py-4 mb-8 text-left">
          <p className="text-text-secondary text-[14px]">{message}</p>
        </div>

        <Link href="/sign-in">
          <Button fullWidth className="!py-3 shadow-md shadow-orange/20">
            Back to Sign In
          </Button>
        </Link>
      </div>
    </main>
  );
}

export default function AuthErrorPage() {
  return (
    <Suspense>
      <AuthErrorContent />
    </Suspense>
  );
}
