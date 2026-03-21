/**
 * Sign In screen — email/password, Google, Apple, and guest sign-in.
 * PWA web version: uses Firebase popup auth for social providers.
 */
import { useState } from 'react';
import { useNavigate } from 'react-router';
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  sendEmailVerification,
  signInAnonymously,
  signInWithGoogle,
  signInWithApple,
} from '../firebase/auth';
import styles from './SignIn.module.css';

export function SignIn() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  async function handleEmailAuth(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setIsLoading(true);

    try {
      if (isSignUp) {
        const user = await createUserWithEmailAndPassword(email, password);
        await sendEmailVerification(user);
        navigate('/verify-email');
      } else {
        const user = await signInWithEmailAndPassword(email, password);
        if (!user.emailVerified) {
          await sendEmailVerification(user);
          navigate('/verify-email');
          return;
        }
        navigate('/');
      }
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setIsLoading(false);
    }
  }

  async function handleGoogle() {
    setError(null);
    setIsLoading(true);
    try {
      await signInWithGoogle();
      navigate('/');
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setIsLoading(false);
    }
  }

  async function handleApple() {
    setError(null);
    setIsLoading(true);
    try {
      await signInWithApple();
      navigate('/');
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setIsLoading(false);
    }
  }

  async function handleGuest() {
    setError(null);
    setIsLoading(true);
    try {
      await signInAnonymously();
      navigate('/');
    } catch (err) {
      setError(friendlyError(err));
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <h1 className={styles.title}>Sundee Fundee</h1>
        <p className={styles.subtitle}>Strength training, your way</p>

        {/* Social auth buttons */}
        <div className={styles.socialButtons}>
          <button className={styles.socialBtn} onClick={handleGoogle} disabled={isLoading}>
            Continue with Google
          </button>
          <button className={styles.socialBtn} onClick={handleApple} disabled={isLoading}>
            Continue with Apple
          </button>
        </div>

        <div className={styles.divider}>
          <span>or</span>
        </div>

        {/* Email form */}
        <form onSubmit={handleEmailAuth} className={styles.form}>
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className={styles.input}
            required
            autoComplete="email"
          />
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className={styles.input}
            required
            minLength={6}
            autoComplete={isSignUp ? 'new-password' : 'current-password'}
          />
          <button type="submit" className={styles.primaryBtn} disabled={isLoading}>
            {isLoading ? 'Loading...' : isSignUp ? 'Create Account' : 'Sign In'}
          </button>
        </form>

        {error && <p className={styles.error}>{error}</p>}

        <button
          className={styles.toggleBtn}
          onClick={() => { setIsSignUp(!isSignUp); setError(null); }}
        >
          {isSignUp ? 'Already have an account? Sign in' : "Don't have an account? Sign up"}
        </button>

        <div className={styles.divider}>
          <span>or</span>
        </div>

        <button className={styles.guestBtn} onClick={handleGuest} disabled={isLoading}>
          Continue as Guest
        </button>
      </div>
    </div>
  );
}

function friendlyError(err: unknown): string {
  const code = (err as { code?: string })?.code ?? '';
  switch (code) {
    case 'auth/invalid-email': return 'Invalid email address.';
    case 'auth/user-disabled': return 'This account has been disabled.';
    case 'auth/user-not-found': return 'No account found with this email.';
    case 'auth/wrong-password': return 'Incorrect password.';
    case 'auth/email-already-in-use': return 'An account with this email already exists.';
    case 'auth/weak-password': return 'Password must be at least 6 characters.';
    case 'auth/popup-closed-by-user': return 'Sign-in popup was closed.';
    case 'auth/cancelled-popup-request': return 'Sign-in was cancelled.';
    default: return (err as { message?: string })?.message ?? 'An error occurred. Please try again.';
  }
}
