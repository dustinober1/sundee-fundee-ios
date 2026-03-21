/**
 * Verify Email screen — shown after email sign-up, waits for verification.
 */
import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router';
import { getAuthInstance } from '../firebase/auth';
import styles from './SignIn.module.css';

export function VerifyEmail() {
  const navigate = useNavigate();
  const [checking, setChecking] = useState(false);

  useEffect(() => {
    const interval = setInterval(async () => {
      const user = getAuthInstance().currentUser;
      if (!user) return;
      setChecking(true);
      await user.reload();
      if (user.emailVerified) {
        clearInterval(interval);
        navigate('/');
      }
      setChecking(false);
    }, 3000);

    return () => clearInterval(interval);
  }, [navigate]);

  return (
    <div className={styles.container}>
      <div className={styles.card}>
        <h1 className={styles.title}>Check your email</h1>
        <p className={styles.subtitle}>
          We sent a verification link to your email address. Click the link to verify your account.
        </p>
        <p style={{ fontSize: 'var(--font-caption)', color: 'var(--text-muted)', marginTop: 16 }}>
          {checking ? 'Checking...' : 'Waiting for verification...'}
        </p>
        <button
          className={styles.primaryBtn}
          style={{ marginTop: 24 }}
          onClick={() => navigate('/sign-in')}
        >
          Back to Sign In
        </button>
      </div>
    </div>
  );
}
