/**
 * Centralized Firebase initialization orchestrator.
 *
 * Initializes all Firebase modules in the correct order at app startup.
 * App Check must be initialized first to secure all subsequent Firebase calls.
 *
 * Initialization order:
 * 1. App Check — secures all subsequent Firebase service calls
 * 2. Crashlytics — crash reporting (sync)
 * 3. Analytics — usage analytics (sync)
 * 4. Messaging — FCM background data handling (async)
 *
 * Guard: module-level `initialized` flag prevents double-init across hot reloads.
 */

import { initAppCheck } from './appCheck';
import { initCrashlytics } from './crashlytics';
import { initAnalytics } from './analytics';
import { initMessaging } from './messaging';

/** Prevent double-initialization across hot reloads. */
let initialized = false;

/**
 * Initialize all Firebase modules.
 * Safe to call multiple times — guards against double-init internally.
 * Must be called at app startup before any Firebase service calls.
 */
export async function initFirebase(): Promise<void> {
  // Guard: already initialized
  if (initialized) return;

  // App Check must be first — secures all subsequent Firebase calls
  await initAppCheck();

  // Crashlytics and Analytics are sync — initialize before messaging
  initCrashlytics();
  initAnalytics();

  // Messaging is async — initialize last
  await initMessaging();

  initialized = true;
  console.log('[Firebase] All modules initialized');
}
