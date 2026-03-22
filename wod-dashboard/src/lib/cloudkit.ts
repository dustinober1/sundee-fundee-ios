"use client";

import type { WOD, Program } from "@/lib/types";
import { exerciseToJSON } from "@/lib/types";

// ─── CloudKit JS SDK Types (minimal declarations) ─────────────────────────

declare global {
  interface Window {
    CloudKit: any;
  }
}

const CK_SCRIPT_URL = "https://cdn.apple-cloudkit.com/ck/2/cloudkit.js";

let _container: any = null;
let _db: any = null;
let _loadPromise: Promise<void> | null = null;
let _authenticated = false;
let _authChangeCallbacks: Array<(authenticated: boolean) => void> = [];

// ─── Initialization ──────────────────────────────────────────────────────────

function loadScript(): Promise<void> {
  if (_loadPromise) return _loadPromise;

  _loadPromise = new Promise((resolve, reject) => {
    if (typeof window === "undefined") {
      reject(new Error("CloudKit JS requires a browser environment"));
      return;
    }

    if (window.CloudKit) {
      resolve();
      return;
    }

    const script = document.createElement("script");
    script.src = CK_SCRIPT_URL;
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => {
      _loadPromise = null;
      reject(new Error("Failed to load CloudKit JS SDK"));
    };
    document.head.appendChild(script);
  });

  return _loadPromise;
}

export async function initCloudKit(): Promise<void> {
  await loadScript();

  if (_container) return;

  const containerId =
    process.env.NEXT_PUBLIC_CLOUDKIT_CONTAINER ?? "";
  const apiToken =
    process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN ?? "";
  const environment =
    process.env.NEXT_PUBLIC_CLOUDKIT_ENV ?? "production";

  if (!containerId || !apiToken) {
    throw new Error(
      "Missing NEXT_PUBLIC_CLOUDKIT_CONTAINER or NEXT_PUBLIC_CLOUDKIT_API_TOKEN"
    );
  }

  window.CloudKit.configure({
    containers: [
      {
        containerIdentifier: containerId,
        apiTokenAuth: {
          apiToken,
          persist: true,
        },
        environment,
      },
    ],
  });

  _container = window.CloudKit.getDefaultContainer();
  _db = _container.publicCloudDatabase;
}

// ─── Authentication ──────────────────────────────────────────────────────────

export function isAuthenticated(): boolean {
  return _authenticated;
}

function notifyAuthChange(authenticated: boolean) {
  _authenticated = authenticated;
  _authChangeCallbacks.forEach((cb) => cb(authenticated));
}

/**
 * Try to set up auth. If user is already signed in (persisted session),
 * returns the user identity. Otherwise returns null.
 * Does NOT show a sign-in UI — use signIn() for that.
 */
export async function setupCloudKitAuth(): Promise<any> {
  await initCloudKit();

  try {
    const userIdentity = await _container.setUpAuth();
    _authenticated = !!userIdentity;

    // Listen for future auth state changes
    _container.whenUserSignsIn().then(() => notifyAuthChange(true));
    _container.whenUserSignsOut().then(() => notifyAuthChange(false));

    return userIdentity;
  } catch {
    // setUpAuth can fail with 421 if origin isn't whitelisted
    // Fall through — user can still try manual sign-in
    _authenticated = false;
    return null;
  }
}

/**
 * Manually trigger Apple ID sign-in using a popup window.
 * The popup handles the OAuth flow and closes itself when done,
 * avoiding the need for a configured callback/redirect URL.
 */
export async function signIn(): Promise<any> {
  await initCloudKit();

  return new Promise((resolve, reject) => {
    // Get the auth URL via our API route (server-side, no Origin header = no 421)
    fetch("/api/cloudkit/auth-url")
      .then((res) => res.json())
      .then((data) => {
        if (!data.redirectURL) {
          // Already authenticated or no redirect needed
          if (data.userRecordName) {
            notifyAuthChange(true);
            resolve(data);
            return;
          }
          reject(new Error("No redirect URL received from CloudKit"));
          return;
        }

        // Open Apple ID sign-in in a popup
        const width = 650;
        const height = 500;
        const left = window.screenX + (window.outerWidth - width) / 2;
        const top = window.screenY + (window.outerHeight - height) / 2;
        const popup = window.open(
          data.redirectURL,
          "cloudkit-auth",
          `width=${width},height=${height},left=${left},top=${top},toolbar=no,menubar=no`
        );

        if (!popup) {
          reject(new Error("Popup was blocked. Please allow popups for this site."));
          return;
        }

        // Poll for the popup closing or auth completing
        const pollInterval = setInterval(async () => {
          try {
            // Check if popup was closed
            if (popup.closed) {
              clearInterval(pollInterval);

              // Check if we're now authenticated
              try {
                const checkRes = await fetch("/api/cloudkit/auth-url");
                const checkData = await checkRes.json();
                if (checkData.userRecordName) {
                  notifyAuthChange(true);
                  resolve(checkData);
                } else {
                  // Re-init and check via CloudKit JS
                  _container = null;
                  _db = null;
                  await initCloudKit();
                  const identity = await _container.setUpAuth();
                  if (identity) {
                    notifyAuthChange(true);
                    resolve(identity);
                  } else {
                    reject(new Error("Sign-in was cancelled or failed."));
                  }
                }
              } catch {
                reject(new Error("Could not verify sign-in status."));
              }
            }
          } catch {
            // Cross-origin errors are expected while popup is on Apple's domain
          }
        }, 500);

        // Timeout after 5 minutes
        setTimeout(() => {
          clearInterval(pollInterval);
          if (!popup.closed) popup.close();
          reject(new Error("Sign-in timed out."));
        }, 5 * 60 * 1000);
      })
      .catch((err) => {
        reject(new Error(`Failed to initiate sign-in: ${err}`));
      });
  });
}

/**
 * Sign out the current user.
 */
export async function signOut(): Promise<void> {
  await initCloudKit();
  // Clear persisted auth
  notifyAuthChange(false);
}

/**
 * Ensures user is authenticated before proceeding.
 */
export async function requireAuth(): Promise<void> {
  if (!_authenticated) {
    throw new Error("Please sign in with Apple ID using the button in the top bar.");
  }
}

/** Register a callback for auth state changes. Returns unsubscribe function. */
export function onAuthChange(callback: (authenticated: boolean) => void): () => void {
  _authChangeCallbacks.push(callback);
  return () => {
    _authChangeCallbacks = _authChangeCallbacks.filter((cb) => cb !== callback);
  };
}

// ─── WOD Records ────────────────────────────────────────────────────────────

export async function saveWODRecord(wod: WOD): Promise<void> {
  await initCloudKit();

  const record = {
    recordType: "WOD",
    recordName: wod.id,
    fields: {
      id: { value: wod.id },
      date: { value: wod.date },
      title: { value: wod.title },
      description: { value: wod.description },
      exercisesJSON: { value: JSON.stringify(wod.exercises.map(exerciseToJSON)) },
    },
  };

  const response = await _db.saveRecords([record]);
  if (response.hasErrors) {
    const errors = response.errors.map((e: any) => e.reason).join(", ");
    throw new Error(`CloudKit save failed: ${errors}`);
  }
}

// ─── Program Records ────────────────────────────────────────────────────────

export async function saveProgramRecord(program: Program): Promise<void> {
  await initCloudKit();

  const record = {
    recordType: "Program",
    recordName: program.id,
    fields: {
      id: { value: program.id },
      name: { value: program.name },
      category: { value: program.category },
      description: { value: program.description },
      durationWeeks: { value: program.durationWeeks },
      sessionsPerWeek: { value: program.sessionsPerWeek },
      difficulty: { value: program.difficulty },
      phasesJSON: { value: JSON.stringify(program.phases) },
      weeksJSON: { value: JSON.stringify(program.weeks) },
      cycleAdjustmentProfileJSON: {
        value: program.cycleAdjustmentProfile
          ? JSON.stringify(program.cycleAdjustmentProfile)
          : null,
      },
    },
  };

  const response = await _db.saveRecords([record]);
  if (response.hasErrors) {
    const errors = response.errors.map((e: any) => e.reason).join(", ");
    throw new Error(`CloudKit save failed: ${errors}`);
  }
}

// ─── Delete Record ──────────────────────────────────────────────────────────

export async function deleteRecord(
  recordType: string,
  recordName: string
): Promise<void> {
  await initCloudKit();

  const response = await _db.deleteRecords([
    { recordName, recordType },
  ]);
  if (response.hasErrors) {
    const errors = response.errors.map((e: any) => e.reason).join(", ");
    throw new Error(`CloudKit delete failed: ${errors}`);
  }
}
