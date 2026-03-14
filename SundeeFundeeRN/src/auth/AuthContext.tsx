/**
 * AuthContext: SessionProvider and useSession hook.
 *
 * SessionProvider listens to Firebase onAuthStateChanged and exposes session state
 * to all child components. Manages signOut (clears Firebase + AsyncStorage).
 *
 * Session shape:
 *   { user, isLoading, isGuest, signOut }
 */
import React, {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
} from 'react';
import auth from '@react-native-firebase/auth';
import type { FirebaseAuthTypes } from '@react-native-firebase/auth';
import AsyncStorage from '@react-native-async-storage/async-storage';

// ─── Types ────────────────────────────────────────────────────────────────────

export interface Session {
  user: FirebaseAuthTypes.User | null;
  isLoading: boolean;
  isGuest: boolean;
  signOut: () => Promise<void>;
}

// ─── Context ──────────────────────────────────────────────────────────────────

const SessionContext = createContext<Session | null>(null);

// ─── SessionProvider ─────────────────────────────────────────────────────────

interface SessionProviderProps {
  children: React.ReactNode;
  /** Optional callback invoked whenever a user signs in (non-null). Used by
   *  the root layout to persist user data to Firestore or AsyncStorage. */
  onUserSignIn?: (user: FirebaseAuthTypes.User) => void;
}

export function SessionProvider({
  children,
  onUserSignIn,
}: SessionProviderProps): React.JSX.Element {
  const [user, setUser] = useState<FirebaseAuthTypes.User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = auth().onAuthStateChanged((firebaseUser) => {
      setUser(firebaseUser);
      setIsLoading(false);
      if (firebaseUser && onUserSignIn) {
        onUserSignIn(firebaseUser);
      }
    });

    return unsubscribe;
  }, [onUserSignIn]);

  const signOut = useCallback(async (): Promise<void> => {
    await auth().signOut();
    await AsyncStorage.clear();
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

// ─── useSession ───────────────────────────────────────────────────────────────

/**
 * Returns the current session from the nearest SessionProvider.
 * Throws if called outside a SessionProvider.
 */
export function useSession(): Session {
  const ctx = useContext(SessionContext);
  if (!ctx) {
    throw new Error(
      'useSession must be used within a SessionProvider. ' +
        'Ensure your component is wrapped in <SessionProvider>.'
    );
  }
  return ctx;
}
