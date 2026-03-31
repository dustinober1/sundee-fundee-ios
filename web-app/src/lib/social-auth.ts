const REDIRECT_PROVIDER_STORAGE_KEY = "sf:authRedirectProvider";

export async function syncSessionCookie(idToken: string): Promise<void> {
  await fetch("/api/auth/session", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idToken }),
  });
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

function isMobile(): boolean {
  return /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
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

  if (isMobile()) {
    markPendingRedirectProvider(provider.providerId);
    await signInWithRedirect(auth, provider);
    // Page will reload — AuthProvider handles session sync on return
    return;
  }

  const result = await signInWithPopup(auth, provider);
  const idToken = await result.user.getIdToken();
  await syncSessionCookie(idToken);
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
    default:
      return `Sign-in failed: ${code || (err as Error).message}`;
  }
}
