"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { ProgramList, type ProgramListItem } from "@/components/program-list";
import { ProgramEditor } from "@/components/program-editor";
import { ProgramGenerator } from "@/components/program-generator";
import { useToast } from "@/components/toast";
import type {
  Program,
  ProgramExerciseJSON,
  ProgramSession,
  ProgramWeek,
} from "@/lib/types";
import { exerciseFromJSON, exerciseToJSON } from "@/lib/types";
import { requireAuth, saveProgramRecord } from "@/lib/cloudkit";

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

interface PublishStatus {
  wods: Record<string, { publishedAt: string }>;
  programs: Record<string, { publishedAt: string }>;
}

export default function ProgramsPage() {
  const { toast } = useToast();
  const [programs, setPrograms] = useState<Program[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [showGenerator, setShowGenerator] = useState(false);
  const [publishStatus, setPublishStatus] = useState<PublishStatus>({ wods: {}, programs: {} });

  // Fetch publish status
  const fetchPublishStatus = useCallback(async () => {
    try {
      const res = await fetch("/api/cloudkit/publish");
      if (res.ok) {
        setPublishStatus(await res.json());
      }
    } catch {
      // Non-critical — ignore
    }
  }, []);

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
    fetchPublishStatus();
  }, [fetchPrograms, fetchPublishStatus]);

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
        published: p.id in publishStatus.programs,
      })),
    [programs, publishStatus]
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
    setSaving(true);
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
    } finally {
      setSaving(false);
    }
  }

  function handleGenerated(raw: any) {
    const decoded = decodeProgram(raw);
    // Merge into local state (replace by ID if already exists, else prepend)
    setPrograms((prev) => {
      const map = new Map(prev.map((p) => [p.id, p]));
      map.set(decoded.id, decoded);
      return [...map.values()];
    });
    setSelectedId(decoded.id);
  }

  async function handlePublishOne(id: string) {
    const program = programs.find((p) => p.id === id);
    if (!program) return;
    try {
      await requireAuth();
      await saveProgramRecord(program);
      await fetch("/api/cloudkit/publish", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ type: "program", id }),
      });
      await fetchPublishStatus();
      toast(`Published program: ${program.name}`, "success");
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
      {/* Generator toggle */}
      <div className="shrink-0">
        <button
          onClick={() => setShowGenerator((v) => !v)}
          className="px-3 py-1.5 border border-navy/20 rounded text-sm font-medium text-navy hover:bg-navy/5 transition-colors"
        >
          {showGenerator ? "Hide Generator" : "Generate Program"}
        </button>
      </div>

      {/* AI generator panel */}
      {showGenerator && (
        <div className="shrink-0">
          <ProgramGenerator onGenerated={handleGenerated} />
        </div>
      )}

      {/* Two-panel layout */}
      <div className="flex flex-1 gap-4 min-h-0">
        {/* Left panel: list */}
        <div className="w-96 shrink-0">
          <ProgramList
            programs={listItems}
            selectedId={selectedId}
            onSelect={setSelectedId}
            onNew={handleNew}
            onPublishOne={handlePublishOne}
          />
        </div>

        {/* Right panel: editor */}
        <div className="flex-1 border border-navy/10 rounded bg-white min-h-0">
          <ProgramEditor
            program={selectedProgram}
            onSave={handleSave}
            onDelete={handleDelete}
            saving={saving}
          />
        </div>
      </div>
    </div>
  );
}
