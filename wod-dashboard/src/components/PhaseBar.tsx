'use client';

import { useState } from 'react';
import { ProgramPhase } from '@/types/program';

interface PhaseBarProps {
  phases: ProgramPhase[];
  totalWeeks: number;
  onChange: (phases: ProgramPhase[]) => void;
}

const PHASE_COLORS = [
  'bg-blue-500',
  'bg-green-500',
  'bg-orange',
  'bg-purple-500',
  'bg-red-500',
  'bg-yellow-500',
];

function emptyPhase(index: number, totalWeeks: number): ProgramPhase {
  return {
    id: `phase-${index + 1}`,
    name: `Phase ${index + 1}`,
    goal: '',
    weekRange: [1, totalWeeks],
  };
}

export default function PhaseBar({ phases, totalWeeks, onChange }: PhaseBarProps) {
  const [editingIndex, setEditingIndex] = useState<number | null>(null);

  function addPhase() {
    const newPhase = emptyPhase(phases.length, totalWeeks);
    onChange([...phases, newPhase]);
    setEditingIndex(phases.length);
  }

  function updatePhase(index: number, updated: ProgramPhase) {
    const newPhases = [...phases];
    newPhases[index] = updated;
    onChange(newPhases);
  }

  function removePhase(index: number) {
    onChange(phases.filter((_, i) => i !== index));
    setEditingIndex(null);
  }

  if (phases.length === 0) {
    return (
      <div className="flex items-center justify-between p-3 bg-cream-dark/30 rounded-lg border border-dashed border-navy/20">
        <span className="text-sm text-navy/40">No phases defined (optional)</span>
        <button
          onClick={addPhase}
          className="px-3 py-1 text-xs font-medium text-orange border border-orange/30 rounded-md hover:bg-orange/10 transition-colors"
        >
          Add Phase
        </button>
      </div>
    );
  }

  return (
    <div>
      {/* Visual bar */}
      <div className="flex h-8 rounded-lg overflow-hidden mb-3">
        {phases.map((phase, i) => {
          const start = phase.weekRange[0];
          const end = phase.weekRange[1];
          const span = end - start + 1;
          const widthPercent = (span / totalWeeks) * 100;
          const colorClass = PHASE_COLORS[i % PHASE_COLORS.length];

          return (
            <button
              key={phase.id}
              onClick={() => setEditingIndex(editingIndex === i ? null : i)}
              className={`${colorClass} text-white text-xs font-bold flex items-center justify-center truncate px-2 hover:opacity-90 transition-opacity ${
                editingIndex === i ? 'ring-2 ring-offset-1 ring-navy' : ''
              }`}
              style={{ width: `${widthPercent}%` }}
              title={`${phase.name}: Weeks ${start}-${end}`}
            >
              {phase.name}
            </button>
          );
        })}
      </div>

      {/* Phase editor */}
      {editingIndex !== null && phases[editingIndex] && (
        <div className="p-3 bg-cream-dark/30 rounded-lg border border-navy/10 mb-3">
          <div className="grid grid-cols-1 sm:grid-cols-4 gap-2">
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">Phase ID</label>
              <input
                type="text"
                value={phases[editingIndex].id}
                onChange={(e) =>
                  updatePhase(editingIndex, { ...phases[editingIndex], id: e.target.value })
                }
                className="w-full px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">Name</label>
              <input
                type="text"
                value={phases[editingIndex].name}
                onChange={(e) =>
                  updatePhase(editingIndex, { ...phases[editingIndex], name: e.target.value })
                }
                className="w-full px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">Goal</label>
              <input
                type="text"
                value={phases[editingIndex].goal}
                onChange={(e) =>
                  updatePhase(editingIndex, { ...phases[editingIndex], goal: e.target.value })
                }
                placeholder="e.g. Build base strength"
                className="w-full px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-navy/60 mb-1">
                Weeks ({phases[editingIndex].weekRange[0]}-{phases[editingIndex].weekRange[1]})
              </label>
              <div className="flex items-center gap-1">
                <input
                  type="number"
                  min={1}
                  max={totalWeeks}
                  value={phases[editingIndex].weekRange[0]}
                  onChange={(e) => {
                    const start = Math.max(1, Math.min(parseInt(e.target.value) || 1, totalWeeks));
                    updatePhase(editingIndex, {
                      ...phases[editingIndex],
                      weekRange: [start, phases[editingIndex].weekRange[1]],
                    });
                  }}
                  className="w-14 px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                />
                <span className="text-navy/40 text-xs">to</span>
                <input
                  type="number"
                  min={1}
                  max={totalWeeks}
                  value={phases[editingIndex].weekRange[1]}
                  onChange={(e) => {
                    const end = Math.max(1, Math.min(parseInt(e.target.value) || 1, totalWeeks));
                    updatePhase(editingIndex, {
                      ...phases[editingIndex],
                      weekRange: [phases[editingIndex].weekRange[0], end],
                    });
                  }}
                  className="w-14 px-2 py-1.5 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
                />
                <button
                  onClick={() => removePhase(editingIndex)}
                  className="ml-auto p-1 text-red-500 hover:bg-red-50 rounded transition-colors"
                  aria-label="Remove phase"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      <button
        onClick={addPhase}
        className="px-3 py-1 text-xs font-medium text-orange border border-orange/30 rounded-md hover:bg-orange/10 transition-colors"
      >
        Add Phase
      </button>
    </div>
  );
}
