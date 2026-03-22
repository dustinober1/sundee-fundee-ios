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

// Sign-in/sign-out button element IDs (CloudKit JS renders Apple ID UI into these)
export const SIGN_IN_BUTTON_ID = "apple-sign-in-button";
export const SIGN_OUT_BUTTON_ID = "apple-sign-out-button";

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
          signInButton: { id: SIGN_IN_BUTTON_ID },
          signOutButton: { id: SIGN_OUT_BUTTON_ID },
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

/**
 * Sets up CloudKit auth. CloudKit JS will render Apple sign-in/sign-out buttons
 * into the DOM elements with the configured IDs. Returns the user identity if
 * already authenticated, or null if the user needs to click the sign-in button.
 */
export async function setupCloudKitAuth(): Promise<any> {
  await initCloudKit();

  const userIdentity = await _container.setUpAuth();
  _authenticated = !!userIdentity;
  return userIdentity;
}

/**
 * Ensures user is authenticated before proceeding. If not authenticated,
 * throws an error prompting the user to sign in via the auth bar.
 */
export async function requireAuth(): Promise<void> {
  if (!_authenticated) {
    throw new Error("Please sign in with Apple ID using the button in the top bar.");
  }
}

/** Listen for auth state changes. */
export function onAuthChange(callback: (authenticated: boolean) => void): void {
  if (!_container) return;
  _container.whenUserSignsIn().then(() => {
    _authenticated = true;
    callback(true);
  });
  _container.whenUserSignsOut().then(() => {
    _authenticated = false;
    callback(false);
  });
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
