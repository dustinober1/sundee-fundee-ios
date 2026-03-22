"use client";

import { useEffect, useState } from "react";
import {
  setupCloudKitAuth,
  signIn,
  signOut,
  isAuthenticated,
} from "@/lib/cloudkit";

export function CloudKitAuth() {
  const [status, setStatus] = useState<"loading" | "signed-in" | "signed-out">(
    "loading"
  );
  const [error, setError] = useState<string | null>(null);
  const [signingIn, setSigningIn] = useState(false);

  useEffect(() => {
    // setupCloudKitAuth is sync — checks URL params and localStorage
    const authenticated = setupCloudKitAuth();
    setStatus(authenticated ? "signed-in" : "signed-out");
  }, []);

  async function handleSignIn() {
    setSigningIn(true);
    setError(null);
    try {
      await signIn();
      // signIn redirects — page will reload
    } catch (e) {
      setError(String(e));
      setSigningIn(false);
    }
  }

  function handleSignOut() {
    signOut();
    setStatus("signed-out");
  }

  if (error) {
    return (
      <div className="flex items-center gap-2 px-4 py-2 bg-red-50 border-b border-red-200 text-sm text-red-700">
        <span>CloudKit: {error}</span>
        <button
          onClick={() => { setError(null); handleSignIn(); }}
          className="ml-2 px-2 py-0.5 bg-red-100 hover:bg-red-200 rounded text-xs font-medium transition-colors"
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-3 px-4 py-2 bg-navy/5 border-b border-navy/10 text-sm">
      <span className="text-navy/60 font-medium">CloudKit:</span>

      {status === "loading" && (
        <span className="text-navy/40">Connecting...</span>
      )}

      {status === "signed-in" && (
        <>
          <span className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-green-500" />
            <span className="text-green-700 font-medium">Signed In</span>
          </span>
          <button
            onClick={handleSignOut}
            className="px-2 py-0.5 border border-navy/20 rounded text-xs font-medium text-navy/60 hover:bg-navy/10 transition-colors"
          >
            Sign Out
          </button>
        </>
      )}

      {status === "signed-out" && (
        <>
          <span className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-orange" />
            <span className="text-navy/70">Not signed in</span>
          </span>
          <button
            onClick={handleSignIn}
            disabled={signingIn}
            className="px-3 py-1 bg-navy text-white rounded text-xs font-medium hover:bg-navy/90 transition-colors disabled:opacity-50"
          >
            {signingIn ? "Signing in..." : "Sign in with Apple ID"}
          </button>
        </>
      )}
    </div>
  );
}
