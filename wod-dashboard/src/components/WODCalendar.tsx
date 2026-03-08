'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { WOD, TemplateType } from '@/types/wod';
import { fetchWODs } from '@/lib/wod-service';

const DAYS_OF_WEEK = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTH_NAMES = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const TEMPLATE_LABELS: Record<TemplateType, string> = {
  strength: 'STR',
  amrap: 'AMRAP',
  emom: 'EMOM',
  forTime: 'FT',
  circuit: 'CIR',
};

const TEMPLATE_COLORS: Record<TemplateType, string> = {
  strength: 'bg-navy text-cream',
  amrap: 'bg-orange text-cream',
  emom: 'bg-gold text-navy',
  forTime: 'bg-navy-light text-cream',
  circuit: 'bg-orange/80 text-cream',
};

function formatDate(year: number, month: number, day: number): string {
  return `${year}-${String(month + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

function getMonthDays(year: number, month: number) {
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const days: (number | null)[] = [];

  // Padding for start of month
  for (let i = 0; i < firstDay; i++) {
    days.push(null);
  }
  for (let d = 1; d <= daysInMonth; d++) {
    days.push(d);
  }
  // Pad end to complete the last row
  while (days.length % 7 !== 0) {
    days.push(null);
  }
  return days;
}

export default function WODCalendar() {
  const router = useRouter();
  const today = new Date();
  const [currentYear, setCurrentYear] = useState(today.getFullYear());
  const [currentMonth, setCurrentMonth] = useState(today.getMonth());
  const [wods, setWods] = useState<WOD[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadWODs = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await fetchWODs();
      setWods(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load WODs');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadWODs();
  }, [loadWODs]);

  // Build a map from date string -> WOD for O(1) lookup
  const wodMap = new Map<string, WOD>();
  for (const wod of wods) {
    wodMap.set(wod.date, wod);
  }

  const days = getMonthDays(currentYear, currentMonth);
  const todayStr = formatDate(today.getFullYear(), today.getMonth(), today.getDate());

  const prevMonth = () => {
    if (currentMonth === 0) {
      setCurrentYear(currentYear - 1);
      setCurrentMonth(11);
    } else {
      setCurrentMonth(currentMonth - 1);
    }
  };

  const nextMonth = () => {
    if (currentMonth === 11) {
      setCurrentYear(currentYear + 1);
      setCurrentMonth(0);
    } else {
      setCurrentMonth(currentMonth + 1);
    }
  };

  const goToToday = () => {
    setCurrentYear(today.getFullYear());
    setCurrentMonth(today.getMonth());
  };

  const handleDayClick = (day: number) => {
    const dateStr = formatDate(currentYear, currentMonth, day);
    router.push(`/editor/${dateStr}`);
  };

  return (
    <div>
      {/* Month navigation */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <h1 className="text-3xl font-bold text-navy">
            {MONTH_NAMES[currentMonth]} {currentYear}
          </h1>
          <button
            onClick={goToToday}
            className="px-3 py-1 text-sm font-medium bg-orange text-cream rounded-md hover:bg-orange/90 transition-colors"
          >
            Today
          </button>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={prevMonth}
            className="p-2 rounded-md bg-navy text-cream hover:bg-navy-light transition-colors"
            aria-label="Previous month"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <button
            onClick={nextMonth}
            className="p-2 rounded-md bg-navy text-cream hover:bg-navy-light transition-colors"
            aria-label="Next month"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>
      </div>

      {/* Legend */}
      <div className="flex items-center gap-4 mb-4 text-sm">
        <div className="flex items-center gap-1.5">
          <span className="inline-block w-3 h-3 rounded-full bg-green-500" />
          <span>Published</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="inline-block w-3 h-3 rounded-full bg-yellow-500" />
          <span>Draft</span>
        </div>
        <div className="flex items-center gap-1.5">
          <span className="inline-block w-3 h-3 rounded-full bg-cream-dark border border-navy/20" />
          <span>Empty</span>
        </div>
      </div>

      {loading && (
        <div className="text-center py-12 text-navy/60">Loading WODs...</div>
      )}

      {error && (
        <div className="text-center py-12">
          <p className="text-red-600 mb-2">{error}</p>
          <button
            onClick={loadWODs}
            className="text-sm text-orange underline hover:no-underline"
          >
            Retry
          </button>
        </div>
      )}

      {!loading && !error && (
        <div className="bg-white rounded-xl shadow-lg border border-navy/10 overflow-hidden">
          {/* Day headers */}
          <div className="grid grid-cols-7 bg-navy text-cream">
            {DAYS_OF_WEEK.map((day) => (
              <div
                key={day}
                className="px-2 py-3 text-center text-sm font-semibold tracking-wider uppercase"
              >
                {day}
              </div>
            ))}
          </div>

          {/* Day cells */}
          <div className="grid grid-cols-7">
            {days.map((day, idx) => {
              if (day === null) {
                return (
                  <div
                    key={`empty-${idx}`}
                    className="min-h-[100px] bg-cream-dark/30 border border-navy/5"
                  />
                );
              }

              const dateStr = formatDate(currentYear, currentMonth, day);
              const wod = wodMap.get(dateStr);
              const isToday = dateStr === todayStr;

              return (
                <button
                  key={dateStr}
                  onClick={() => handleDayClick(day)}
                  className={`min-h-[100px] p-2 border border-navy/5 text-left transition-colors hover:bg-orange/10 cursor-pointer group ${
                    isToday ? 'bg-orange/5 ring-2 ring-inset ring-orange' : 'bg-white'
                  }`}
                >
                  <div className="flex items-start justify-between">
                    <span
                      className={`inline-flex items-center justify-center w-7 h-7 rounded-full text-sm font-medium ${
                        isToday
                          ? 'bg-orange text-cream'
                          : 'text-navy group-hover:text-orange'
                      }`}
                    >
                      {day}
                    </span>
                    {wod && (
                      <span
                        className={`inline-block w-2.5 h-2.5 rounded-full ${
                          wod.status === 'published'
                            ? 'bg-green-500'
                            : 'bg-yellow-500'
                        }`}
                      />
                    )}
                  </div>
                  {wod && (
                    <div className="mt-1.5 space-y-1">
                      <p className="text-xs font-medium text-navy truncate leading-tight">
                        {wod.title}
                      </p>
                      <span
                        className={`inline-block px-1.5 py-0.5 rounded text-[10px] font-bold tracking-wider ${
                          TEMPLATE_COLORS[wod.templateType]
                        }`}
                      >
                        {TEMPLATE_LABELS[wod.templateType]}
                      </span>
                    </div>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
