const REDIRECT_PROVIDER_STORAGE_KEY = "sf:authRedirectProvider";

export async function syncSessionCookie(idToken: string): Promise<void> {
  const response = await fetch("/api/auth/session", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idToken }),
  });

  if (!response.ok) {
    const payload = (await response.json().catch(() => null)) as { error?: string } | null;
    const message = payload?.error ?? "We couldn't finish signing you in on the server.";
    const error = new Error(message) as Error & { code?: string };
    error.code = "auth/session-cookie-sync-failed";
    throw error;
  }
}

export function markPendingRedirectProvider(providerId: string): void {
  if (typeof window === "undefined") return;
  window.sessionStorage.setItem(REDIRECT_PROVIDER_STORAGE_KEY, providerId);
}

export function getPendingRedirectProvider(): string | null {
  if (typeof window === "undefined") return null;
  return window.sessionStorage.getItem(REDIRECT_PROVIDER_STORAGE_KEY);
}

export function clearPendingRedirectProvider(): void {
  if (typeof window === "undefined") return;
  window.sessionStorage.removeItem(REDIRECT_PROVIDER_STORAGE_KEY);
}

function shouldFallbackToRedirect(error: unknown): boolean {
  const code = (error as { code?: string }).code;

  return (
    code === "auth/popup-blocked" ||
    code === "auth/popup-closed-by-user" ||
    code === "auth/cancelled-popup-request" ||
    code === "auth/operation-not-supported-in-this-environment"
  );
}

export async function signInWithGoogle(): Promise<void> {
  const {
    signInWithPopup,
    signInWithRedirect,
    GoogleAuthProvider,
  } = await import("firebase/auth");
  const { getFirebaseAuth } = await import("@/lib/firebase");
  const auth = getFirebaseAuth();
  const provider = new GoogleAuthProvider();

  try {
    const result = await signInWithPopup(auth, provider);
    const idToken = await result.user.getIdToken();
    await syncSessionCookie(idToken);
    clearPendingRedirectProvider();
    return;
  } catch (error) {
    if (!shouldFallbackToRedirect(error)) {
      throw error;
    }

    markPendingRedirectProvider(provider.providerId);
    await signInWithRedirect(auth, provider);
    // Page will reload — AuthProvider handles session sync on return.
  }
}

export function socialAuthErrorMessage(err: unknown): string {
  const code = (err as { code?: string }).code;
  switch (code) {
    case "auth/popup-closed-by-user":
      return "Sign-in was cancelled.";
    case "auth/unauthorized-domain":
      return "This domain is not authorized. Check Firebase Console settings.";
    case "auth/operation-not-allowed":
      return "This sign-in method is not enabled. Please enable it in Firebase Console.";
    case "auth/account-exists-with-different-credential":
      return "An account already exists with this email using a different sign-in method.";
    case "auth/missing-initial-state":
      return "We couldn't finish Google sign-in in this browser session. Please try again in Safari, not the installed home screen app.";
    case "auth/session-cookie-sync-failed":
      return (err as Error).message;
    default:
      return `Sign-in failed: ${code || (err as Error).message}`;
  }
}
