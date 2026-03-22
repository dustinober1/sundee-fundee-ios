"use client";

import { useEffect, useState } from "react";
import {
  initCloudKit,
  setupCloudKitAuth,
  onAuthChange,
  SIGN_IN_BUTTON_ID,
  SIGN_OUT_BUTTON_ID,
} from "@/lib/cloudkit";

export function CloudKitAuth() {
  const [status, setStatus] = useState<"loading" | "signed-in" | "signed-out">(
    "loading"
  );
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function init() {
      try {
        await initCloudKit();
        const userIdentity = await setupCloudKitAuth();
        if (cancelled) return;
        setStatus(userIdentity ? "signed-in" : "signed-out");

        // Listen for future auth changes
        onAuthChange((authenticated) => {
          if (!cancelled) {
            setStatus(authenticated ? "signed-in" : "signed-out");
          }
        });
      } catch (e) {
        if (!cancelled) {
          setError(String(e));
          setStatus("signed-out");
        }
      }
    }

    init();
    return () => {
      cancelled = true;
    };
  }, []);

  if (error) {
    return (
      <div className="flex items-center gap-2 px-4 py-2 bg-red-50 border-b border-red-200 text-sm text-red-700">
        <span>CloudKit: {error}</span>
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
          {/* CloudKit JS renders the sign-out button here */}
          <div id={SIGN_OUT_BUTTON_ID} className="inline-block" />
        </>
      )}

      {status === "signed-out" && (
        <>
          <span className="flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-orange" />
            <span className="text-navy/70">Sign in to publish</span>
          </span>
          {/* CloudKit JS renders the Apple ID sign-in button here */}
          <div id={SIGN_IN_BUTTON_ID} className="inline-block" />
        </>
      )}
    </div>
  );
}
