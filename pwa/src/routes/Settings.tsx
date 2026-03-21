/**
 * Settings screen — account info, unit preference, rest timer, Stripe subscription.
 */
import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router';
import { useSession } from '../auth/AuthContext';
import { useEntitlementContext } from '../entitlements/EntitlementContext';
import { getSettingsRepo, DEFAULT_SETTINGS, type AppSettings } from '../repositories/SettingsRepo';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { getFirebaseApp } from '../firebase/app';
import styles from './Settings.module.css';

export function Settings() {
  const { user, isGuest, signOut } = useSession();
  const { isPremium } = useEntitlementContext();
  const navigate = useNavigate();

  const [settings, setSettings] = useState<AppSettings>(DEFAULT_SETTINGS);
  const [isSigningOut, setIsSigningOut] = useState(false);

  useEffect(() => {
    if (!user) return;
    const repo = getSettingsRepo(isGuest);
    repo.getSettings(user.uid).then((s) => {
      if (s) setSettings(s);
    }).catch(() => {});
  }, [user, isGuest]);

  const saveSettings = useCallback(async (updated: AppSettings) => {
    setSettings(updated);
    if (!user) return;
    const repo = getSettingsRepo(isGuest);
    await repo.saveSettings(user.uid, updated).catch(() => {});
  }, [user, isGuest]);

  async function handleManageSubscription() {
    try {
      const functions = getFunctions(getFirebaseApp());
      const createPortalSession = httpsCallable(functions, 'createPortalSession');
      const result = await createPortalSession({
        returnUrl: window.location.href,
      });
      const { url } = result.data as { url: string };
      window.open(url, '_blank');
    } catch {
      // Portal not yet configured — graceful fallback
      alert('Subscription management is being set up. Please try again later.');
    }
  }

  async function handleSignOut() {
    setIsSigningOut(true);
    try {
      await signOut();
      navigate('/sign-in');
    } catch {
      setIsSigningOut(false);
    }
  }

  return (
    <div className={styles.container}>
      <h1 className={styles.title}>Settings</h1>

      {/* Account section */}
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Account</h2>
        <div className={styles.row}>
          <span className={styles.label}>Email</span>
          <span className={styles.value}>{isGuest ? 'Guest' : user?.email ?? '—'}</span>
        </div>
        {isGuest && (
          <button className={styles.primaryBtn} onClick={() => navigate('/sign-in')}>
            Create Account
          </button>
        )}
      </section>

      {/* Subscription section */}
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Subscription</h2>
        <div className={styles.row}>
          <span className={styles.label}>Plan</span>
          <span className={`${styles.value} ${isPremium ? styles.premium : ''}`}>
            {isPremium ? 'Premium' : 'Free'}
          </span>
        </div>
        {isPremium ? (
          <button className={styles.secondaryBtn} onClick={handleManageSubscription}>
            Manage Subscription
          </button>
        ) : (
          <button className={styles.primaryBtn} onClick={() => navigate('/pricing')}>
            Upgrade to Premium
          </button>
        )}
      </section>

      {/* Preferences section */}
      <section className={styles.section}>
        <h2 className={styles.sectionTitle}>Preferences</h2>

        <div className={styles.row}>
          <span className={styles.label}>Weight Unit</span>
          <div className={styles.toggle}>
            <button
              className={`${styles.toggleOption} ${settings.weightUnit === 'lb' ? styles.toggleActive : ''}`}
              onClick={() => saveSettings({ ...settings, weightUnit: 'lb' })}
            >
              lb
            </button>
            <button
              className={`${styles.toggleOption} ${settings.weightUnit === 'kg' ? styles.toggleActive : ''}`}
              onClick={() => saveSettings({ ...settings, weightUnit: 'kg' })}
            >
              kg
            </button>
          </div>
        </div>

        <div className={styles.row}>
          <span className={styles.label}>Rest Timer (sec)</span>
          <select
            className={styles.select}
            value={settings.defaultRestDuration}
            onChange={(e) => saveSettings({ ...settings, defaultRestDuration: Number(e.target.value) })}
          >
            {[30, 60, 90, 120, 150, 180].map((v) => (
              <option key={v} value={v}>{v}s</option>
            ))}
          </select>
        </div>
      </section>

      {/* Sign out */}
      {!isGuest && (
        <section className={styles.section}>
          <button
            className={styles.dangerBtn}
            onClick={handleSignOut}
            disabled={isSigningOut}
          >
            {isSigningOut ? 'Signing out...' : 'Sign Out'}
          </button>
        </section>
      )}
    </div>
  );
}
