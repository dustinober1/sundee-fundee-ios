/**
 * Firebase Analytics — web implementation.
 */
import {
  getAnalytics,
  logEvent as fbLogEvent,
  setUserProperties as fbSetUserProperties,
  type Analytics,
} from 'firebase/analytics';
import { getFirebaseApp } from './app';

let analyticsInstance: Analytics | null = null;

function getAnalyticsInstance(): Analytics | null {
  if (analyticsInstance) return analyticsInstance;

  try {
    analyticsInstance = getAnalytics(getFirebaseApp());
    return analyticsInstance;
  } catch {
    // Analytics may fail in environments without cookie support
    return null;
  }
}

export function initAnalytics(): void {
  getAnalyticsInstance();
}

export async function logEvent(
  eventName: string,
  params?: Record<string, string | number | boolean>,
): Promise<void> {
  const analytics = getAnalyticsInstance();
  if (!analytics) return;

  try {
    fbLogEvent(analytics, eventName, params);
  } catch {
    // Non-fatal
  }
}

export async function setUserProperties(props: {
  subscriptionTier: 'free' | 'premium';
  cycleTrackingEnabled: boolean;
}): Promise<void> {
  const analytics = getAnalyticsInstance();
  if (!analytics) return;

  try {
    fbSetUserProperties(analytics, {
      subscription_tier: props.subscriptionTier,
      cycle_tracking_enabled: String(props.cycleTrackingEnabled),
    });
  } catch {
    // Non-fatal
  }
}
