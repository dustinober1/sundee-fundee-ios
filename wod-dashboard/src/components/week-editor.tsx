"use client";

import { useState } from "react";
import { SessionEditor } from "@/components/session-editor";
import type { ProgramPhase, ProgramSession, ProgramWeek } from "@/lib/types";

// ─── Props ───────────────────────────────────────────────────────────────────

interface WeekEditorProps {
  week: ProgramWeek;
  weekIndex: number;
  phases: ProgramPhase[];
  onChange: (updated: ProgramWeek) => void;
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

let sessionCounter = 0;

function blankSession(): ProgramSession {
  sessionCounter += 1;
  return {
    sessionId: `session-${Date.now()}-${sessionCounter}`,
    sessionName: `Session ${sessionCounter}`,
    sessionType: "Lift",
    focus: "",
    exercises: [],
  };
}

// ─── Component ───────────────────────────────────────────────────────────────

export function WeekEditor({ week, weekIndex, phases, onChange }: WeekEditorProps) {
  const [expanded, setExpanded] = useState(false);

  function updateSession(index: number, updated: ProgramSession) {
    const newSessions = week.sessions.map((s, i) =>
      i === index ? updated : s
    );
    onChange({ ...week, sessions: newSessions });
  }

  function deleteSession(index: number) {
    const newSessions = week.sessions.filter((_, i) => i !== index);
    onChange({ ...week, sessions: newSessions });
  }

  function addSession() {
    onChange({ ...week, sessions: [...week.sessions, blankSession()] });
  }

  return (
    <div className="border border-navy/10 rounded mb-3 bg-cream/30">
      {/* Header */}
      <button
        type="button"
        onClick={() => setExpanded((prev) => !prev)}
        className="w-full flex items-center gap-2 p-3 text-left hover:bg-navy/5 transition-colors"
      >
        <span className="text-navy/40 text-sm">{expanded ? "▼" : "▶"}</span>
        <span className="text-sm font-bold text-navy">
          Week {week.week}
        </span>
        {week.phaseId && (
          <span className="text-xs bg-navy/10 text-navy/60 px-1.5 py-0.5 rounded">
            {week.phaseId}
          </span>
        )}
        {week.isTestWeek && (
          <span className="text-xs bg-yellow-100 text-yellow-700 px-1.5 py-0.5 rounded">
            Test
          </span>
        )}
        <span className="text-xs text-navy/40 ml-auto">
          {week.sessions.length} session(s)
        </span>
      </button>

      {/* Expanded content */}
      {expanded && (
        <div className="px-3 pb-3 border-t border-navy/10">
          {/* Week settings */}
          <div className="flex items-center gap-4 py-3">
            <div className="flex items-center gap-2">
              <label className="text-sm text-navy/70">Phase:</label>
              <select
                value={week.phaseId ?? ""}
                onChange={(e) =>
                  onChange({
                    ...week,
                    phaseId: e.target.value === "" ? undefined : e.target.value,
                  })
                }
                className="border border-navy/20 rounded px-2 py-1 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40"
              >
                <option value="">None</option>
                {phases.map((phase) => (
                  <option key={phase.id} value={phase.id}>
                    {phase.name || phase.id}
                  </option>
                ))}
              </select>
            </div>

            <label className="flex items-center gap-2 text-sm text-navy/70 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={week.isTestWeek ?? false}
                onChange={(e) =>
                  onChange({
                    ...week,
                    isTestWeek: e.target.checked || undefined,
                  })
                }
                className="accent-navy"
              />
              Test Week
            </label>
          </div>

          {/* Sessions */}
          {week.sessions.map((session, i) => (
            <SessionEditor
              key={session.sessionId}
              session={session}
              onChange={(updated) => updateSession(i, updated)}
              onDelete={() => deleteSession(i)}
            />
          ))}

          <button
            type="button"
            onClick={addSession}
            className="text-sm text-orange hover:text-orange/80 font-medium mt-1"
          >
            + Add Session
          </button>
        </div>
      )}
    </div>
  );
}
