import type { RecoveryPhase } from "./types";

// ---------------------------------------------------------------------------
// Body Regions
// ---------------------------------------------------------------------------

export interface BodyRegion {
  id: string;
  displayName: string;
  /** Maps to the injury engine's contraindication key */
  engineKey: string;
}

export const BODY_REGIONS: BodyRegion[] = [
  { id: "head",            displayName: "Head",            engineKey: "head" },
  { id: "neck",            displayName: "Neck",            engineKey: "neck" },
  { id: "shoulder_left",   displayName: "Left Shoulder",   engineKey: "shoulder" },
  { id: "shoulder_right",  displayName: "Right Shoulder",  engineKey: "shoulder" },
  { id: "chest",           displayName: "Chest",           engineKey: "chest" },
  { id: "upper_back",      displayName: "Upper Back",      engineKey: "back" },
  { id: "lower_back",      displayName: "Lower Back",      engineKey: "back" },
  { id: "elbow_left",      displayName: "Left Elbow",      engineKey: "elbow" },
  { id: "elbow_right",     displayName: "Right Elbow",     engineKey: "elbow" },
  { id: "wrist_left",      displayName: "Left Wrist",      engineKey: "wrist" },
  { id: "wrist_right",     displayName: "Right Wrist",     engineKey: "wrist" },
  { id: "hip_left",        displayName: "Left Hip",        engineKey: "hip" },
  { id: "hip_right",       displayName: "Right Hip",       engineKey: "hip" },
  { id: "knee_left",       displayName: "Left Knee",       engineKey: "knee" },
  { id: "knee_right",      displayName: "Right Knee",      engineKey: "knee" },
  { id: "ankle_left",      displayName: "Left Ankle",      engineKey: "ankle" },
  { id: "ankle_right",     displayName: "Right Ankle",     engineKey: "ankle" },
];

const _regionMap = new Map(BODY_REGIONS.map((r) => [r.id, r]));

/**
 * Parses a comma-separated string of region IDs into BodyRegion objects.
 * Unrecognised IDs are silently dropped.
 */
export function parseRegions(raw: string): BodyRegion[] {
  if (!raw.trim()) return [];
  return raw
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s.length > 0)
    .flatMap((id) => {
      const region = _regionMap.get(id);
      return region ? [region] : [];
    });
}

/**
 * Encodes an array of BodyRegion objects to a comma-separated string of IDs.
 */
export function encodeRegions(regions: BodyRegion[]): string {
  return regions.map((r) => r.id).join(",");
}

// ---------------------------------------------------------------------------
// Recovery Phase
// ---------------------------------------------------------------------------

/** Canonical ordering from acute (most severe) to resolved. */
export const RECOVERY_PHASE_ORDER: RecoveryPhase[] = [
  "acute",
  "rehab",
  "lightLoad",
  "returnToPlay",
  "resolved",
];

export function recoveryPhaseDisplayName(phase: RecoveryPhase): string {
  switch (phase) {
    case "acute":        return "Acute";
    case "rehab":        return "Rehab";
    case "lightLoad":    return "Light Load";
    case "returnToPlay": return "Return to Play";
    case "resolved":     return "Resolved";
  }
}
