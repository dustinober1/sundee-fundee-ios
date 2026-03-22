"use client";

import type {
  ProgramCycleAdjustmentProfile,
  ProgramPhaseAdjustmentSettings,
} from "@/lib/types";

// ─── Constants ────────────────────────────────────────────────────────────────

const CYCLE_PHASES = ["menstrual", "follicular", "ovulation", "luteal"] as const;
type CyclePhase = (typeof CYCLE_PHASES)[number];

const DEFAULT_PHASE_SETTINGS: ProgramPhaseAdjustmentSettings = {
  loadMultiplier: 1.0,
  setsMultiplier: 1.0,
  repsMultiplier: 1.0,
};

function buildDefaultProfile(): ProgramCycleAdjustmentProfile {
  const phaseSettings: Record<string, ProgramPhaseAdjustmentSettings> = {};
  for (const phase of CYCLE_PHASES) {
    phaseSettings[phase] = { ...DEFAULT_PHASE_SETTINGS };
  }
  return {
    fallbackPhase: "follicular",
    lowConfidenceScale: 0.7,
    phaseSettings,
  };
}

// ─── Props ────────────────────────────────────────────────────────────────────

interface CycleAdjustmentEditorProps {
  profile: ProgramCycleAdjustmentProfile | null;
  onChange: (profile: ProgramCycleAdjustmentProfile | null) => void;
}

// ─── Component ────────────────────────────────────────────────────────────────

export function CycleAdjustmentEditor({
  profile,
  onChange,
}: CycleAdjustmentEditorProps) {
  const enabled = profile !== null;

  function handleToggle(checked: boolean) {
    if (checked) {
      onChange(buildDefaultProfile());
    } else {
      onChange(null);
    }
  }

  function handleFallbackPhase(value: string) {
    if (!profile) return;
    onChange({ ...profile, fallbackPhase: value });
  }

  function handleLowConfidenceScale(value: number) {
    if (!profile) return;
    onChange({ ...profile, lowConfidenceScale: value });
  }

  function handlePhaseMultiplier(
    phase: CyclePhase,
    key: keyof ProgramPhaseAdjustmentSettings,
    value: number
  ) {
    if (!profile) return;
    const existing = profile.phaseSettings[phase] ?? { ...DEFAULT_PHASE_SETTINGS };
    onChange({
      ...profile,
      phaseSettings: {
        ...profile.phaseSettings,
        [phase]: { ...existing, [key]: value },
      },
    });
  }

  return (
    <div className="mb-6">
      <h3 className="text-sm font-bold text-navy mb-2">Cycle Adjustments</h3>

      {/* ── Enable toggle ─────────────────────────────────────────────── */}
      <label className="flex items-center gap-2 text-sm text-navy/70 mb-3">
        <input
          type="checkbox"
          checked={enabled}
          onChange={(e) => handleToggle(e.target.checked)}
          className="accent-navy"
        />
        Has Cycle Adjustments
      </label>

      {/* ── Editor (only when enabled) ────────────────────────────────── */}
      {enabled && profile && (
        <div className="border border-navy/10 rounded p-3 bg-white space-y-4">

          {/* Fallback phase + low confidence scale */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">
                Fallback Phase
              </label>
              <select
                value={profile.fallbackPhase}
                onChange={(e) => handleFallbackPhase(e.target.value)}
                className="w-full border border-navy/20 rounded px-2 py-1 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
              >
                {CYCLE_PHASES.map((phase) => (
                  <option key={phase} value={phase}>
                    {phase.charAt(0).toUpperCase() + phase.slice(1)}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">
                Low Confidence Scale (0–1)
              </label>
              <input
                type="number"
                min={0}
                max={1}
                step={0.1}
                value={profile.lowConfidenceScale}
                onChange={(e) =>
                  handleLowConfidenceScale(parseFloat(e.target.value) || 0)
                }
                className="w-full border border-navy/20 rounded px-2 py-1 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
              />
            </div>
          </div>

          {/* Phase settings table */}
          <div>
            <p className="text-xs font-medium text-navy/60 mb-2">Phase Multipliers</p>
            <table className="w-full text-sm border-collapse">
              <thead>
                <tr className="text-xs text-navy/50 border-b border-navy/10">
                  <th className="text-left py-1 pr-3 font-medium w-28">Phase</th>
                  <th className="text-center py-1 px-2 font-medium">Load</th>
                  <th className="text-center py-1 px-2 font-medium">Sets</th>
                  <th className="text-center py-1 px-2 font-medium">Reps</th>
                </tr>
              </thead>
              <tbody>
                {CYCLE_PHASES.map((phase) => {
                  const settings =
                    profile.phaseSettings[phase] ?? { ...DEFAULT_PHASE_SETTINGS };
                  return (
                    <tr key={phase} className="border-b border-navy/5 last:border-0">
                      <td className="py-1.5 pr-3 text-navy/70 capitalize font-medium">
                        {phase}
                      </td>
                      {(
                        [
                          "loadMultiplier",
                          "setsMultiplier",
                          "repsMultiplier",
                        ] as const
                      ).map((key) => (
                        <td key={key} className="py-1.5 px-2 text-center">
                          <input
                            type="number"
                            step={0.01}
                            value={settings[key]}
                            onChange={(e) =>
                              handlePhaseMultiplier(
                                phase,
                                key,
                                parseFloat(e.target.value) || 0
                              )
                            }
                            className="w-20 border border-navy/20 rounded px-1.5 py-0.5 text-sm text-center bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
                          />
                        </td>
                      ))}
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
