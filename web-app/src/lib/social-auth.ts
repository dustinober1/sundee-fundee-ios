export async function signInWithGoogle(): Promise<void> {
  const { signInWithPopup, GoogleAuthProvider } = await import("firebase/auth");
  const { getFirebaseAuth } = await import("@/lib/firebase");
  const auth = getFirebaseAuth();
  await signInWithPopup(auth, new GoogleAuthProvider());
}

export async function signInWithApple(): Promise<void> {
  const { signInWithPopup, OAuthProvider, updateProfile } = await import(
    "firebase/auth"
  );
  const { getFirebaseAuth } = await import("@/lib/firebase");
  const auth = getFirebaseAuth();

  const provider = new OAuthProvider("apple.com");
  provider.addScope("email");
  provider.addScope("name");

  const result = await signInWithPopup(auth, provider);

  // Apple only sends the user's name on the very first authorization.
  // If displayName is missing, extract it from the Apple ID token.
  if (!result.user.displayName) {
    const credential = OAuthProvider.credentialFromResult(result);
    const idToken = credential?.idToken;
    if (idToken) {
      try {
        const payload = JSON.parse(atob(idToken.split(".")[1]));
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
    default:
      return `Sign-in failed: ${code || (err as Error).message}`;
  }
}
