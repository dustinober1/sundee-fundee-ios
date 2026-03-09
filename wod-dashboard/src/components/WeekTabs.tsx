'use client';

import { useState } from 'react';
import { ProgramWeek } from '@/types/program';

interface WeekTabsProps {
  weeks: ProgramWeek[];
  selectedWeek: number;
  onSelectWeek: (weekIndex: number) => void;
  onCopyWeek: (sourceWeekIndex: number, targetWeekIndex: number) => void;
}

export default function WeekTabs({
  weeks,
  selectedWeek,
  onSelectWeek,
  onCopyWeek,
}: WeekTabsProps) {
  const [showCopyDropdown, setShowCopyDropdown] = useState(false);

  return (
    <div className="flex items-center gap-1 flex-wrap">
      {weeks.map((week, i) => (
        <button
          key={i}
          onClick={() => onSelectWeek(i)}
          className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
            selectedWeek === i
              ? 'bg-navy text-cream'
              : 'bg-cream-dark/50 text-navy/60 hover:text-navy hover:bg-cream-dark'
          }`}
        >
          W{week.week}
          {week.isTestWeek && (
            <span className="ml-1 text-[10px] text-gold font-bold">TEST</span>
          )}
        </button>
      ))}

      {/* Copy from dropdown */}
      <div className="relative ml-2">
        <button
          onClick={() => setShowCopyDropdown(!showCopyDropdown)}
          className="px-2 py-1.5 text-xs font-medium text-navy/50 border border-navy/15 rounded-md hover:text-navy hover:border-navy/30 transition-colors"
          title="Copy week"
        >
          Copy from...
        </button>
        {showCopyDropdown && (
          <div className="absolute z-40 top-full mt-1 left-0 bg-white border border-navy/20 rounded-lg shadow-lg py-1 min-w-[140px]">
            {weeks.map((week, i) => (
              <button
                key={i}
                disabled={i === selectedWeek}
                onClick={() => {
                  onCopyWeek(i, selectedWeek);
                  setShowCopyDropdown(false);
                }}
                className={`w-full text-left px-3 py-1.5 text-sm ${
                  i === selectedWeek
                    ? 'text-navy/20 cursor-not-allowed'
                    : 'text-navy hover:bg-cream-dark/50'
                }`}
              >
                Week {week.week}
                {i === selectedWeek && ' (current)'}
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
