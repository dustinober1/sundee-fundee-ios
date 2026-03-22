"use client";

import type { WOD, Program } from "@/lib/types";
import { exerciseToJSON } from "@/lib/types";

// ─── State ──────────────────────────────────────────────────────────────────

let _ckWebAuthToken: string | null = null;
let _authenticated = false;
let _authChangeCallbacks: Array<(authenticated: boolean) => void> = [];

const AUTH_TOKEN_KEY = "ckWebAuthToken";

// ─── Helpers ────────────────────────────────────────────────────────────────

function getConfig() {
  return {
    containerId: process.env.NEXT_PUBLIC_CLOUDKIT_CONTAINER ?? "",
    apiToken: process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN ?? "",
    environment: process.env.NEXT_PUBLIC_CLOUDKIT_ENV ?? "production",
  };
}

function notifyAuthChange(authenticated: boolean) {
  _authenticated = authenticated;
  _authChangeCallbacks.forEach((cb) => cb(authenticated));
}

// ─── Authentication ──────────────────────────────────────────────────────────

export function isAuthenticated(): boolean {
  return _authenticated;
}

/**
 * Check for auth tokens: URL params (after redirect) or localStorage (persisted).
 */
export function setupCloudKitAuth(): boolean {
  if (typeof window === "undefined") return false;

  // Check URL for auth tokens from Apple redirect
  const params = new URLSearchParams(window.location.search);
  const tokenFromUrl = params.get("ckWebAuthToken");

  if (tokenFromUrl) {
    _ckWebAuthToken = tokenFromUrl;
    _authenticated = true;

    // Persist to localStorage
    try { localStorage.setItem(AUTH_TOKEN_KEY, tokenFromUrl); } catch {}

    // Clean URL
    const url = new URL(window.location.href);
    url.searchParams.delete("ckWebAuthToken");
    url.searchParams.delete("ckSession");
    window.history.replaceState({}, "", url.pathname);

    return true;
  }

  // Check localStorage for persisted token
  try {
    const persisted = localStorage.getItem(AUTH_TOKEN_KEY);
    if (persisted) {
      _ckWebAuthToken = persisted;
      _authenticated = true;
      return true;
    }
  } catch {}

  return false;
}

/**
 * Redirect to Apple ID sign-in. Uses server-side proxy to get redirect URL.
 */
export async function signIn(): Promise<void> {
  const res = await fetch("/api/cloudkit/auth-url");
  const data = await res.json();

  if (data.redirectURL) {
    window.location.href = data.redirectURL;
  } else {
    throw new Error("Could not get sign-in URL from CloudKit.");
  }
}

/**
 * Sign out — clear persisted token.
 */
export function signOut(): void {
  _ckWebAuthToken = null;
  _authenticated = false;
  try { localStorage.removeItem(AUTH_TOKEN_KEY); } catch {}
  notifyAuthChange(false);
}

/**
 * Ensures user is authenticated before proceeding.
 */
export function requireAuth(): void {
  if (!_authenticated || !_ckWebAuthToken) {
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

// ─── CloudKit API (server-side proxy) ───────────────────────────────────────

async function cloudKitRequest(
  method: "POST" | "GET",
  path: string,
  body?: any
): Promise<any> {
  const res = await fetch("/api/cloudkit/request", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      ckMethod: method,
      path,
      body,
      ckWebAuthToken: _ckWebAuthToken,
    }),
  });
  const data = await res.json();
  if (data.error) throw new Error(data.error);
  return data;
}

// ─── WOD Records ────────────────────────────────────────────────────────────

export async function saveWODRecord(wod: WOD): Promise<void> {
  requireAuth();

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

  const data = await cloudKitRequest("POST", "records/modify", {
    operations: [{ operationType: "forceReplace", record }],
  });

  if (data.hasErrors || data.records?.[0]?.serverErrorCode) {
    const reason = data.records?.[0]?.reason ?? data.reason ?? "Unknown error";
    throw new Error(`CloudKit save failed: ${reason}`);
  }
}

// ─── Program Records ────────────────────────────────────────────────────────

export async function saveProgramRecord(program: Program): Promise<void> {
  requireAuth();

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

  const data = await cloudKitRequest("POST", "records/modify", {
    operations: [{ operationType: "forceReplace", record }],
  });

  if (data.hasErrors || data.records?.[0]?.serverErrorCode) {
    const reason = data.records?.[0]?.reason ?? data.reason ?? "Unknown error";
    throw new Error(`CloudKit save failed: ${reason}`);
  }
}

// ─── Delete Record ──────────────────────────────────────────────────────────

export async function deleteRecord(
  recordType: string,
  recordName: string
): Promise<void> {
  requireAuth();

  const data = await cloudKitRequest("POST", "records/modify", {
    operations: [{ operationType: "delete", record: { recordType, recordName } }],
  });

  if (data.hasErrors || data.records?.[0]?.serverErrorCode) {
    const reason = data.records?.[0]?.reason ?? data.reason ?? "Unknown error";
    throw new Error(`CloudKit delete failed: ${reason}`);
  }
}
