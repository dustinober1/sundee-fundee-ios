import { describe, it, expect } from "vitest";
import {
  BODY_REGIONS,
  parseRegions,
  encodeRegions,
  RECOVERY_PHASE_ORDER,
  recoveryPhaseDisplayName,
} from "../body-location";

// ---------------------------------------------------------------------------
// BODY_REGIONS
// ---------------------------------------------------------------------------

describe("BODY_REGIONS", () => {
  it("contains exactly 17 regions", () => {
    expect(BODY_REGIONS).toHaveLength(17);
  });

  it("all regions have a non-empty id, displayName, and engineKey", () => {
    for (const r of BODY_REGIONS) {
      expect(r.id.length).toBeGreaterThan(0);
      expect(r.displayName.length).toBeGreaterThan(0);
      expect(r.engineKey.length).toBeGreaterThan(0);
    }
  });

  it("head has engineKey 'head'", () => {
    const r = BODY_REGIONS.find((b) => b.id === "head");
    expect(r?.engineKey).toBe("head");
  });

  it("neck has engineKey 'neck'", () => {
    const r = BODY_REGIONS.find((b) => b.id === "neck");
    expect(r?.engineKey).toBe("neck");
  });

  it("shoulder_left and shoulder_right have engineKey 'shoulder'", () => {
    const left  = BODY_REGIONS.find((b) => b.id === "shoulder_left");
    const right = BODY_REGIONS.find((b) => b.id === "shoulder_right");
    expect(left?.engineKey).toBe("shoulder");
    expect(right?.engineKey).toBe("shoulder");
  });

  it("chest has engineKey 'chest'", () => {
    const r = BODY_REGIONS.find((b) => b.id === "chest");
    expect(r?.engineKey).toBe("chest");
  });

  it("upper_back and lower_back have engineKey 'back'", () => {
    const upper = BODY_REGIONS.find((b) => b.id === "upper_back");
    const lower = BODY_REGIONS.find((b) => b.id === "lower_back");
    expect(upper?.engineKey).toBe("back");
    expect(lower?.engineKey).toBe("back");
  });

  it("elbows have engineKey 'elbow'", () => {
    const left  = BODY_REGIONS.find((b) => b.id === "elbow_left");
    const right = BODY_REGIONS.find((b) => b.id === "elbow_right");
    expect(left?.engineKey).toBe("elbow");
    expect(right?.engineKey).toBe("elbow");
  });

  it("wrists have engineKey 'wrist'", () => {
    const left  = BODY_REGIONS.find((b) => b.id === "wrist_left");
    const right = BODY_REGIONS.find((b) => b.id === "wrist_right");
    expect(left?.engineKey).toBe("wrist");
    expect(right?.engineKey).toBe("wrist");
  });

  it("hips have engineKey 'hip'", () => {
    const left  = BODY_REGIONS.find((b) => b.id === "hip_left");
    const right = BODY_REGIONS.find((b) => b.id === "hip_right");
    expect(left?.engineKey).toBe("hip");
    expect(right?.engineKey).toBe("hip");
  });

  it("knees have engineKey 'knee'", () => {
    const left  = BODY_REGIONS.find((b) => b.id === "knee_left");
    const right = BODY_REGIONS.find((b) => b.id === "knee_right");
    expect(left?.engineKey).toBe("knee");
    expect(right?.engineKey).toBe("knee");
  });

  it("ankles have engineKey 'ankle'", () => {
    const left  = BODY_REGIONS.find((b) => b.id === "ankle_left");
    const right = BODY_REGIONS.find((b) => b.id === "ankle_right");
    expect(left?.engineKey).toBe("ankle");
    expect(right?.engineKey).toBe("ankle");
  });

  it("all region ids are unique", () => {
    const ids = BODY_REGIONS.map((r) => r.id);
    expect(new Set(ids).size).toBe(ids.length);
  });
});

// ---------------------------------------------------------------------------
// parseRegions / encodeRegions
// ---------------------------------------------------------------------------

describe("parseRegions", () => {
  it("parses a single region", () => {
    const result = parseRegions("head");
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe("head");
  });

  it("parses multiple regions", () => {
    const result = parseRegions("knee_left,ankle_right");
    expect(result).toHaveLength(2);
    expect(result[0].id).toBe("knee_left");
    expect(result[1].id).toBe("ankle_right");
  });

  it("trims whitespace around region ids", () => {
    const result = parseRegions(" shoulder_left , shoulder_right ");
    expect(result).toHaveLength(2);
    expect(result[0].id).toBe("shoulder_left");
    expect(result[1].id).toBe("shoulder_right");
  });

  it("silently drops unknown region ids", () => {
    const result = parseRegions("knee_left,unknown_region");
    expect(result).toHaveLength(1);
    expect(result[0].id).toBe("knee_left");
  });

  it("returns empty array for empty string", () => {
    expect(parseRegions("")).toEqual([]);
  });

  it("returns empty array for whitespace-only string", () => {
    expect(parseRegions("   ")).toEqual([]);
  });
});

describe("encodeRegions", () => {
  it("encodes a single region to its id", () => {
    const regions = parseRegions("head");
    expect(encodeRegions(regions)).toBe("head");
  });

  it("encodes multiple regions as comma-separated ids", () => {
    const regions = parseRegions("knee_left,ankle_right");
    expect(encodeRegions(regions)).toBe("knee_left,ankle_right");
  });

  it("encodes an empty array to empty string", () => {
    expect(encodeRegions([])).toBe("");
  });
});

describe("parse/encode round-trip", () => {
  it("round-trips a multi-region string", () => {
    const original = "shoulder_left,lower_back,knee_right";
    expect(encodeRegions(parseRegions(original))).toBe(original);
  });

  it("round-trips all 17 regions", () => {
    const all = BODY_REGIONS.map((r) => r.id).join(",");
    expect(encodeRegions(parseRegions(all))).toBe(all);
  });
});

// ---------------------------------------------------------------------------
// Recovery Phase
// ---------------------------------------------------------------------------

describe("RECOVERY_PHASE_ORDER", () => {
  it("contains exactly 5 phases", () => {
    expect(RECOVERY_PHASE_ORDER).toHaveLength(5);
  });

  it("starts with acute", () => {
    expect(RECOVERY_PHASE_ORDER[0]).toBe("acute");
  });

  it("ends with resolved", () => {
    expect(RECOVERY_PHASE_ORDER[4]).toBe("resolved");
  });

  it("follows the correct order: acute → rehab → lightLoad → returnToPlay → resolved", () => {
    expect(RECOVERY_PHASE_ORDER).toEqual([
      "acute",
      "rehab",
      "lightLoad",
      "returnToPlay",
      "resolved",
    ]);
  });
});

describe("recoveryPhaseDisplayName", () => {
  it("acute → 'Acute'", () => {
    expect(recoveryPhaseDisplayName("acute")).toBe("Acute");
  });

  it("rehab → 'Rehab'", () => {
    expect(recoveryPhaseDisplayName("rehab")).toBe("Rehab");
  });

  it("lightLoad → 'Light Load'", () => {
    expect(recoveryPhaseDisplayName("lightLoad")).toBe("Light Load");
  });

  it("returnToPlay → 'Return to Play'", () => {
    expect(recoveryPhaseDisplayName("returnToPlay")).toBe("Return to Play");
  });

  it("resolved → 'Resolved'", () => {
    expect(recoveryPhaseDisplayName("resolved")).toBe("Resolved");
  });
});
