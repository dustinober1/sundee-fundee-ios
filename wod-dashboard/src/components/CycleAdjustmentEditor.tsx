'use client';

import {
  ProgramCycleAdjustmentProfile,
  ProgramCycleAdjustmentPhaseSettings,
} from '@/types/program';

interface CycleAdjustmentEditorProps {
  profile: ProgramCycleAdjustmentProfile | null | undefined;
  onChange: (profile: ProgramCycleAdjustmentProfile | null) => void;
}

const DEFAULT_PROFILE: ProgramCycleAdjustmentProfile = {
  fallbackPhase: 'luteal',
  lowConfidenceScale: 0.9,
  phaseSettings: {
    menstrual: { loadMultiplier: 0.85, setsMultiplier: 0.85, repsMultiplier: 1.0 },
    follicular: { loadMultiplier: 1.0, setsMultiplier: 1.0, repsMultiplier: 1.0 },
    ovulatory: { loadMultiplier: 1.05, setsMultiplier: 1.0, repsMultiplier: 1.0 },
    luteal: { loadMultiplier: 0.9, setsMultiplier: 0.9, repsMultiplier: 1.1 },
  },
};

const CYCLE_PHASES = ['menstrual', 'follicular', 'ovulatory', 'luteal'] as const;

export default function CycleAdjustmentEditor({
  profile,
  onChange,
}: CycleAdjustmentEditorProps) {
  const isEnabled = profile != null;

  function toggleEnabled() {
    if (isEnabled) {
      onChange(null);
    } else {
      onChange({ ...DEFAULT_PROFILE });
    }
  }

  function updateSetting(
    phase: string,
    field: keyof ProgramCycleAdjustmentPhaseSettings,
    value: number
  ) {
    if (!profile) return;
    onChange({
      ...profile,
      phaseSettings: {
        ...profile.phaseSettings,
        [phase]: {
          ...profile.phaseSettings[phase],
          [field]: value,
        },
      },
    });
  }

  return (
    <details className="border border-navy/10 rounded-lg">
      <summary className="px-4 py-2 text-sm font-medium text-navy/60 cursor-pointer hover:text-navy">
        Cycle Adjustment Profile {isEnabled && <span className="text-green-600">(Active)</span>}
      </summary>
      <div className="px-4 py-3 space-y-3">
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={isEnabled}
            onChange={toggleEnabled}
            className="rounded border-navy/30"
          />
          <span className="text-navy">Enable cycle-aware adjustments</span>
        </label>

        {isEnabled && profile && (
          <>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium text-navy/60 mb-1">
                  Fallback Phase
                </label>
                <select
                  value={profile.fallbackPhase}
                  onChange={(e) => onChange({ ...profile, fallbackPhase: e.target.value })}
                  className="w-full px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                >
                  {CYCLE_PHASES.map((p) => (
                    <option key={p} value={p}>
                      {p.charAt(0).toUpperCase() + p.slice(1)}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-navy/60 mb-1">
                  Low Confidence Scale
                </label>
                <input
                  type="number"
                  min={0}
                  max={1}
                  step={0.05}
                  value={profile.lowConfidenceScale}
                  onChange={(e) =>
                    onChange({ ...profile, lowConfidenceScale: parseFloat(e.target.value) || 0.9 })
                  }
                  className="w-full px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                />
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="text-xs text-navy/60 font-medium">
                    <th className="text-left py-1 pr-2">Phase</th>
                    <th className="text-center py-1 px-2">Load</th>
                    <th className="text-center py-1 px-2">Sets</th>
                    <th className="text-center py-1 px-2">Reps</th>
                  </tr>
                </thead>
                <tbody>
                  {CYCLE_PHASES.map((phase) => {
                    const settings = profile.phaseSettings[phase] || {
                      loadMultiplier: 1,
                      setsMultiplier: 1,
                      repsMultiplier: 1,
                    };
                    return (
                      <tr key={phase}>
                        <td className="py-1 pr-2 text-navy font-medium capitalize">{phase}</td>
                        <td className="py-1 px-1">
                          <input
                            type="number"
                            min={0}
                            max={2}
                            step={0.05}
                            value={settings.loadMultiplier}
                            onChange={(e) =>
                              updateSetting(phase, 'loadMultiplier', parseFloat(e.target.value) || 1)
                            }
                            className="w-16 px-1.5 py-1 border border-navy/20 rounded text-center text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                          />
                        </td>
                        <td className="py-1 px-1">
                          <input
                            type="number"
                            min={0}
                            max={2}
                            step={0.05}
                            value={settings.setsMultiplier}
                            onChange={(e) =>
                              updateSetting(phase, 'setsMultiplier', parseFloat(e.target.value) || 1)
                            }
                            className="w-16 px-1.5 py-1 border border-navy/20 rounded text-center text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                          />
                        </td>
                        <td className="py-1 px-1">
                          <input
                            type="number"
                            min={0}
                            max={2}
                            step={0.05}
                            value={settings.repsMultiplier}
                            onChange={(e) =>
                              updateSetting(phase, 'repsMultiplier', parseFloat(e.target.value) || 1)
                            }
                            className="w-16 px-1.5 py-1 border border-navy/20 rounded text-center text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                          />
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </>
        )}
      </div>
    </details>
  );
}
