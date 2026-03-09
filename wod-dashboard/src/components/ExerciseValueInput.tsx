'use client';

import { ExerciseValue } from '@/types/program';

type ValueMode = 'fixed' | 'range' | 'amrap' | 'text';

function detectMode(value: ExerciseValue): ValueMode {
  if (value === 'AMRAP') return 'amrap';
  if (Array.isArray(value)) return 'range';
  if (typeof value === 'number') return 'fixed';
  // String that's not AMRAP
  return 'text';
}

interface ExerciseValueInputProps {
  label: string;
  value: ExerciseValue;
  onChange: (value: ExerciseValue) => void;
}

export default function ExerciseValueInput({ label, value, onChange }: ExerciseValueInputProps) {
  const mode = detectMode(value);

  function handleModeChange(newMode: ValueMode) {
    switch (newMode) {
      case 'fixed':
        onChange(typeof value === 'number' ? value : 3);
        break;
      case 'range':
        onChange(Array.isArray(value) ? value : [8, 12]);
        break;
      case 'amrap':
        onChange('AMRAP');
        break;
      case 'text':
        onChange(typeof value === 'string' && value !== 'AMRAP' ? value : '30s');
        break;
    }
  }

  return (
    <div>
      <label className="block text-xs font-medium text-navy/60 mb-1">{label}</label>
      <div className="flex gap-1.5">
        <select
          value={mode}
          onChange={(e) => handleModeChange(e.target.value as ValueMode)}
          className="px-1.5 py-2 border border-navy/20 rounded-md bg-white text-navy text-xs focus:outline-none focus:ring-2 focus:ring-orange w-[72px]"
        >
          <option value="fixed">#</option>
          <option value="range">Range</option>
          <option value="amrap">AMRAP</option>
          <option value="text">Text</option>
        </select>

        {mode === 'fixed' && (
          <input
            type="number"
            min={0}
            value={typeof value === 'number' ? value : 0}
            onChange={(e) => onChange(parseInt(e.target.value) || 0)}
            className="flex-1 min-w-0 px-2 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
          />
        )}

        {mode === 'range' && (
          <div className="flex items-center gap-1 flex-1">
            <input
              type="number"
              min={0}
              value={Array.isArray(value) ? value[0] : 8}
              onChange={(e) => {
                const lo = parseInt(e.target.value) || 0;
                const hi = Array.isArray(value) ? value[1] : 12;
                onChange([lo, hi]);
              }}
              className="w-14 px-2 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
            <span className="text-navy/40 text-xs">-</span>
            <input
              type="number"
              min={0}
              value={Array.isArray(value) ? value[1] : 12}
              onChange={(e) => {
                const lo = Array.isArray(value) ? value[0] : 8;
                const hi = parseInt(e.target.value) || 0;
                onChange([lo, hi]);
              }}
              className="w-14 px-2 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
            />
          </div>
        )}

        {mode === 'amrap' && (
          <div className="flex-1 flex items-center px-2 py-2 bg-orange/10 border border-orange/20 rounded-md">
            <span className="text-xs font-bold text-orange tracking-wider">AMRAP</span>
          </div>
        )}

        {mode === 'text' && (
          <input
            type="text"
            value={typeof value === 'string' && value !== 'AMRAP' ? value : ''}
            onChange={(e) => onChange(e.target.value || '')}
            placeholder="e.g. 30s, 200m"
            className="flex-1 min-w-0 px-2 py-2 border border-navy/20 rounded-md bg-white text-navy text-sm focus:outline-none focus:ring-2 focus:ring-orange"
          />
        )}
      </div>
    </div>
  );
}
