/**
 * useEmailAuth — Email/password authentication hook.
 *
 * Provides signUp and signIn functions with verification enforcement.
 * Unverified users are signed out immediately after signIn per locked decision.
 */
import { useState, useCallback } from 'react';
import auth from '@react-native-firebase/auth';
import { getAuthErrorMessage } from './authErrors';

export interface EmailAuthState {
  signUp: (email: string, password: string) => Promise<{ needsVerification: boolean }>;
  signIn: (email: string, password: string) => Promise<unknown>;
  isLoading: boolean;
  error: string | null;
}

export function useEmailAuth(): EmailAuthState {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const signUp = useCallback(
    async (email: string, password: string): Promise<{ needsVerification: boolean }> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await auth().createUserWithEmailAndPassword(email, password);
        await result.user.sendEmailVerification();
        return { needsVerification: true };
      } catch (err) {
        setError(getAuthErrorMessage(err));
        throw err;
      } finally {
        setIsLoading(false);
      }
    },
    []
  );

  const signIn = useCallback(
    async (email: string, password: string): Promise<unknown> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await auth().signInWithEmailAndPassword(email, password);
        if (!result.user.emailVerified) {
          // Sign out unverified users immediately — per locked decision
          await auth().signOut();
          const message = 'Please verify your email before signing in.';
          setError(message);
          // Throw to signal failure without double-setting error in catch
          throw Object.assign(new Error(message), { _verificationError: true });
        }
        return result.user;
      } catch (err) {
        // If error was already set by verification gate, don't overwrite it
        if (err instanceof Error && (err as Error & { _verificationError?: boolean })._verificationError) {
          throw err;
        }
        setError(getAuthErrorMessage(err));
        throw err;
      } finally {
        setIsLoading(false);
      }
    },
    []
  );

  return { signUp, signIn, isLoading, error };
}
