"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import type { Auth, User } from "firebase/auth";

interface AuthContextType {
  user: User | null;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType>({ user: null, loading: true });

export function useAuth() {
  return useContext(AuthContext);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let unsubscribe: (() => void) | undefined;
    let cancelled = false;

    async function setupAuth() {
      const {
        browserLocalPersistence,
        indexedDBLocalPersistence,
        onIdTokenChanged,
        setPersistence,
      } = await import("firebase/auth");
      const { getFirebaseAuth } = await import("@/lib/firebase");
      const { syncSessionCookie } = await import("@/lib/social-auth");
      const auth = getFirebaseAuth();
      const authWithReady = auth as Auth & { authStateReady?: () => Promise<void> };

      try {
        await setPersistence(auth, indexedDBLocalPersistence);
      } catch {
        await setPersistence(auth, browserLocalPersistence);
      }

      if (typeof authWithReady.authStateReady === "function") {
        await authWithReady.authStateReady();
      }

      if (cancelled) {
        return;
      }

      unsubscribe = onIdTokenChanged(auth, async (firebaseUser) => {
        if (cancelled) {
          return;
        }

        setUser(firebaseUser);
        setLoading(false);

        if (firebaseUser) {
          const idToken = await firebaseUser.getIdToken();
          try {
            await syncSessionCookie(idToken);
          } catch (error) {
            console.error("[auth] Failed to sync session cookie", error);
          }
        } else {
          await fetch("/api/auth/session", { method: "DELETE" });
        }
      });
    }

    setupAuth();
    return () => {
      cancelled = true;
      unsubscribe?.();
    };
  }, []);

  return (
    <AuthContext.Provider value={{ user, loading }}>
      {children}
    </AuthContext.Provider>
  );
}
