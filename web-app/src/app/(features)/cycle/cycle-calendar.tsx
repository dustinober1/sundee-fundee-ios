"use client";

import { useState } from "react";
import { Card } from "@/components/ui/card";
import type { CyclePhase } from "@/lib/domain";
import type { CalendarDayData } from "@/lib/domain";
import { getCycleCalendarData } from "@/lib/domain";
import type { CycleSettings, PeriodLog } from "@/lib/domain";

const PHASE_DAY_BG: Record<CyclePhase, string> = {
  menstrual: "bg-warm-rose text-white",
  follicular: "bg-gold/30 text-navy",
  ovulation: "bg-orange/30 text-navy",
  luteal: "bg-navy/10 text-navy",
};

const PHASE_LEGEND: { phase: CyclePhase; label: string; color: string }[] = [
  { phase: "menstrual", label: "Menstrual", color: "bg-warm-rose" },
  { phase: "follicular", label: "Follicular", color: "bg-gold/50" },
  { phase: "ovulation", label: "Ovulation", color: "bg-orange/50" },
  { phase: "luteal", label: "Luteal", color: "bg-navy/20" },
];

const DAY_HEADERS = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"];

interface CycleCalendarProps {
  periodLogs: PeriodLog[];
  settings: CycleSettings;
}

export function CycleCalendar({ periodLogs, settings }: CycleCalendarProps) {
  const now = new Date();
  const [month, setMonth] = useState(now.getMonth() + 1);
  const [year, setYear] = useState(now.getFullYear());

  const data = getCycleCalendarData(periodLogs, settings, month, year);

  const firstDayOfWeek = new Date(year, month - 1, 1).getDay();

  function prevMonth() {
    if (month === 1) {
      setMonth(12);
      setYear(year - 1);
    } else {
      setMonth(month - 1);
    }
  }

  function nextMonth() {
    if (month === 12) {
      setMonth(1);
      setYear(year + 1);
    } else {
      setMonth(month + 1);
    }
  }

  const monthName = new Date(year, month - 1).toLocaleString("default", { month: "long" });

  return (
    <Card>
      <div className="flex items-center justify-between mb-3">
        <button
          type="button"
          onClick={prevMonth}
          className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-separator/30 transition-colors text-text-secondary"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
          </svg>
        </button>
        <h3 className="font-heading font-bold text-[15px]">
          {monthName} {year}
        </h3>
        <button
          type="button"
          onClick={nextMonth}
          className="w-8 h-8 flex items-center justify-center rounded-full hover:bg-separator/30 transition-colors text-text-secondary"
        >
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
          </svg>
        </button>
      </div>

      <div className="grid grid-cols-7 gap-1 text-center mb-1">
        {DAY_HEADERS.map((d) => (
          <div key={d} className="text-[9px] font-mono text-text-secondary uppercase tracking-wider py-1">
            {d}
          </div>
        ))}
      </div>

      <div className="grid grid-cols-7 gap-1">
        {Array.from({ length: firstDayOfWeek }).map((_, i) => (
          <div key={`empty-${i}`} />
        ))}

        {data.map((entry) => (
          <CalendarDay key={entry.date.getDate()} entry={entry} />
        ))}
      </div>

      <div className="flex gap-3 justify-center mt-3 pt-3 border-t border-separator/30">
        {PHASE_LEGEND.map((item) => (
          <div key={item.phase} className="flex items-center gap-1">
            <div className={`w-2 h-2 rounded-sm ${item.color}`} />
            <span className="text-[9px] text-text-secondary">{item.label}</span>
          </div>
        ))}
      </div>
    </Card>
  );
}

function CalendarDay({ entry }: { entry: CalendarDayData }) {
  const dayNum = entry.date.getDate();
  const phaseClass = entry.phase ? PHASE_DAY_BG[entry.phase] : "text-text-secondary/40";
  const todayRing = entry.isToday ? "ring-2 ring-orange ring-offset-1" : "";

  return (
    <div
      className={`aspect-square flex items-center justify-center rounded-md text-[11px] font-medium ${phaseClass} ${todayRing}`}
    >
      {dayNum}
    </div>
  );
}
