/**
 * AuthContext: SessionProvider and useSession hook.
 * Adapted from the existing RN AuthContext — uses localStorage instead of AsyncStorage.
 */
import { createContext, useContext, useEffect, useState, useCallback, type ReactNode } from 'react';
import {
  onAuthStateChanged,
  signOut as firebaseSignOut,
  type AuthUser,
} from '../firebase/auth';

export interface Session {
  user: AuthUser | null;
  isLoading: boolean;
  isGuest: boolean;
  signOut: () => Promise<void>;
}

const SessionContext = createContext<Session | null>(null);

interface SessionProviderProps {
  children: ReactNode;
  onUserSignIn?: (user: AuthUser) => void;
}

export function SessionProvider({
  children,
  onUserSignIn,
}: SessionProviderProps) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged((firebaseUser) => {
      setUser(firebaseUser);
      setIsLoading(false);
      if (firebaseUser && onUserSignIn) {
        onUserSignIn(firebaseUser);
      }
    });

    return unsubscribe;
  }, [onUserSignIn]);

  const signOut = useCallback(async (): Promise<void> => {
    await firebaseSignOut();
    localStorage.clear();
  }, []);

  const session: Session = {
    user,
    isLoading,
    isGuest: user?.isAnonymous === true,
    signOut,
  };

  return (
    <SessionContext.Provider value={session}>
      {children}
    </SessionContext.Provider>
  );
}

export function useSession(): Session {
  const ctx = useContext(SessionContext);
  if (!ctx) {
    throw new Error(
      'useSession must be used within a SessionProvider.',
    );
  }
  return ctx;
}
