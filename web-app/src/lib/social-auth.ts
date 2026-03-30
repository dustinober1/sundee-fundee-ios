async function syncSessionCookie(idToken: string): Promise<void> {
  await fetch("/api/auth/session", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ idToken }),
  });
}

function isMobile(): boolean {
  return /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
}

export async function updateAppleDisplayName(
  result: import("firebase/auth").UserCredential,
): Promise<void> {
  const { OAuthProvider, updateProfile } = await import("firebase/auth");

  if (result.user.displayName) return;

  const credential = OAuthProvider.credentialFromResult(result);
  const appleIdToken = credential?.idToken;
  if (!appleIdToken) return;

  try {
    const payload = JSON.parse(atob(appleIdToken.split(".")[1]));
    const firstName = payload.first_name ?? payload.given_name ?? "";
    const lastName = payload.last_name ?? payload.family_name ?? "";
    const fullName = [firstName, lastName].filter(Boolean).join(" ");
    if (fullName) {
      await updateProfile(result.user, { displayName: fullName });
    }
  } catch {
    // ID token parsing failed — not critical
  }
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
    await signInWithRedirect(auth, provider);
    // Page will reload — AuthProvider handles session sync on return
    return;
  }

  const result = await signInWithPopup(auth, provider);
  const idToken = await result.user.getIdToken();
  await syncSessionCookie(idToken);
}

export async function signInWithApple(): Promise<void> {
  const {
    signInWithRedirect,
    OAuthProvider,
  } = await import("firebase/auth");
  const { getFirebaseAuth } = await import("@/lib/firebase");
  const auth = getFirebaseAuth();

  const provider = new OAuthProvider("apple.com");
  provider.addScope("email");
  provider.addScope("name");

  // Always use redirect for Apple — popups are blocked by browsers
  // because dynamic imports delay the popup past the user-gesture window.
  // The redirect result is handled in useEffect on the sign-in/sign-up pages.
  await signInWithRedirect(auth, provider);
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
