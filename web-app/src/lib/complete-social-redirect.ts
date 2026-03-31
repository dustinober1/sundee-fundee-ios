type RedirectCompletionResult =
  | { status: "success" }
  | { status: "idle" }
  | { status: "error"; message: string };

function providerLabel(providerId: string): string {
  switch (providerId) {
    case "google.com":
      return "Google";
    default:
      return "social";
  }
}

async function waitForAuthState(
  auth: import("firebase/auth").Auth,
  onAuthStateChanged: typeof import("firebase/auth").onAuthStateChanged,
): Promise<void> {
  const authWithReady = auth as import("firebase/auth").Auth & {
    authStateReady?: () => Promise<void>;
  };

  if (typeof authWithReady.authStateReady === "function") {
    await authWithReady.authStateReady();
    return;
  }

  await new Promise<void>((resolve) => {
    const unsubscribe = onAuthStateChanged(
      auth,
      () => {
        unsubscribe();
        resolve();
      },
      () => resolve(),
    );
  });
}

export async function completeSocialRedirect(): Promise<RedirectCompletionResult> {
  const [
    { getRedirectResult, onAuthStateChanged },
    { getFirebaseAuth },
    {
      clearPendingRedirectProvider,
      getPendingRedirectProvider,
      socialAuthErrorMessage,
      syncSessionCookie,
    },
  ] = await Promise.all([
    import("firebase/auth"),
    import("@/lib/firebase"),
    import("@/lib/social-auth"),
  ]);

  const auth = getFirebaseAuth();
  const pendingProvider = getPendingRedirectProvider();

  console.info("[auth] Completing redirect", {
    authDomain: auth.config.authDomain,
    pendingProvider,
  });

  try {
    const result = await getRedirectResult(auth);
    console.info("[auth] getRedirectResult resolved", {
      hasUser: Boolean(result?.user),
      providerId: result?.providerId ?? null,
    });

    if (result?.user) {
      const idToken = await result.user.getIdToken();
      await syncSessionCookie(idToken);
      clearPendingRedirectProvider();
      return { status: "success" };
    }
  } catch (err) {
    console.error("[auth] getRedirectResult failed", err);
    clearPendingRedirectProvider();
    return { status: "error", message: socialAuthErrorMessage(err) };
  }

  await waitForAuthState(auth, onAuthStateChanged);
  console.info("[auth] Auth state settled", {
    currentUser: auth.currentUser?.uid ?? null,
  });

  if (auth.currentUser) {
    const idToken = await auth.currentUser.getIdToken();
    await syncSessionCookie(idToken);
    clearPendingRedirectProvider();
    return { status: "success" };
  }

  if (pendingProvider) {
    console.warn("[auth] Redirect returned without a Firebase user", {
      authDomain: auth.config.authDomain,
      pendingProvider,
    });
    clearPendingRedirectProvider();
    return {
      status: "error",
      message: `We couldn't finish your ${providerLabel(pendingProvider)} sign-in. Please try again.`,
    };
  }

  return { status: "idle" };
}
