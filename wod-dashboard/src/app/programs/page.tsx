"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { ProgramList, type ProgramListItem } from "@/components/program-list";
import { ProgramEditor } from "@/components/program-editor";
import { useToast } from "@/components/toast";
import type {
  Program,
  ProgramExerciseJSON,
  ProgramSession,
  ProgramWeek,
} from "@/lib/types";
import { exerciseFromJSON, exerciseToJSON } from "@/lib/types";

// ─── Helpers ─────────────────────────────────────────────────────────────────

function blankProgram(): Program {
  return {
    id: "",
    name: "",
    category: "",
    description: "",
    durationWeeks: 0,
    sessionsPerWeek: 3,
    difficulty: "Beginner",
    phases: [],
    weeks: [],
  };
}

/** Decode raw JSON exercises in every session of every week. */
function decodeProgram(raw: any): Program {
  const weeks: ProgramWeek[] = (raw.weeks ?? []).map((w: any) => ({
    week: w.week,
    phaseId: w.phaseId,
    isTestWeek: w.isTestWeek,
    sessions: (w.sessions ?? []).map((s: any) => ({
      sessionId: s.sessionId,
      sessionName: s.sessionName,
      sessionType: s.sessionType,
      focus: s.focus,
      exercises: (s.exercises ?? []).map((ex: ProgramExerciseJSON) =>
        exerciseFromJSON(ex)
      ),
    })),
  }));

  return {
    id: raw.id,
    name: raw.name,
    category: raw.category ?? "",
    description: raw.description ?? "",
    durationWeeks: raw.durationWeeks ?? weeks.length,
    sessionsPerWeek: raw.sessionsPerWeek ?? 3,
    difficulty: raw.difficulty ?? "Beginner",
    phases: raw.phases ?? [],
    weeks,
    cycleAdjustmentProfile: raw.cycleAdjustmentProfile,
  };
}

/** Encode typed Program back to JSON-safe shape for the API. */
function encodeProgram(program: Program): any {
  return {
    ...program,
    weeks: program.weeks.map((w) => ({
      ...w,
      sessions: w.sessions.map((s: ProgramSession) => ({
        ...s,
        exercises: s.exercises.map(exerciseToJSON),
      })),
    })),
  };
}

// ─── Page ────────────────────────────────────────────────────────────────────

export default function ProgramsPage() {
  const { toast } = useToast();
  const [programs, setPrograms] = useState<Program[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  // Fetch programs
  const fetchPrograms = useCallback(async () => {
    try {
      const res = await fetch("/api/programs");
      if (!res.ok) throw new Error("Failed to fetch programs");
      const raw = await res.json();
      setPrograms(Array.isArray(raw) ? raw.map(decodeProgram) : []);
    } catch (e) {
      toast(String(e), "error");
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    fetchPrograms();
  }, [fetchPrograms]);

  // Derived data
  const selectedProgram = useMemo(
    () => programs.find((p) => p.id === selectedId) ?? null,
    [programs, selectedId]
  );

  const listItems: ProgramListItem[] = useMemo(
    () =>
      programs.map((p) => ({
        id: p.id,
        name: p.name,
        category: p.category,
        difficulty: p.difficulty,
        durationWeeks: p.durationWeeks,
        sessionsPerWeek: p.sessionsPerWeek,
        published: false, // local-only for now
      })),
    [programs]
  );

  // Handlers
  function handleNew() {
    const newProgram = blankProgram();
    // Add to local state if not already there
    setPrograms((prev) => {
      if (prev.some((p) => p.id === newProgram.id && newProgram.id !== ""))
        return prev;
      return [...prev, newProgram];
    });
    setSelectedId(newProgram.id);
  }

  async function handleSave(program: Program) {
    try {
      const res = await fetch("/api/programs", {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(encodeProgram(program)),
      });
      if (!res.ok) throw new Error("Failed to save program");
      toast("Program saved", "success");
      await fetchPrograms();
      setSelectedId(program.id);
    } catch (e) {
      toast(String(e), "error");
    }
  }

  async function handleDelete(id: string) {
    try {
      const res = await fetch(`/api/programs?id=${encodeURIComponent(id)}`, {
        method: "DELETE",
      });
      if (!res.ok) throw new Error("Failed to delete program");
      toast("Program deleted", "success");
      setSelectedId(null);
      await fetchPrograms();
    } catch (e) {
      toast(String(e), "error");
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full text-navy/40">
        Loading programs...
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full gap-4 p-4">
      {/* Two-panel layout */}
      <div className="flex flex-1 gap-4 min-h-0">
        {/* Left panel: list */}
        <div className="w-96 shrink-0">
          <ProgramList
            programs={listItems}
            selectedId={selectedId}
            onSelect={setSelectedId}
            onNew={handleNew}
          />
        </div>

        {/* Right panel: editor */}
        <div className="flex-1 border border-navy/10 rounded bg-white min-h-0">
          <ProgramEditor
            program={selectedProgram}
            onSave={handleSave}
            onDelete={handleDelete}
          />
        </div>
      </div>
    </div>
  );
}
