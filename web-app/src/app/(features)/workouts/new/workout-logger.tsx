"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { FormAlert } from "@/components/ui/form-alert";
import { PageHeader, SectionHeader } from "@/components/ui/art-deco";
import { saveWorkout } from "../actions";
import { getErrorMessage } from "@/lib/client-errors";
import { WeightUnit, toKilograms, fromKilograms } from "@/lib/domain";

interface SetEntry {
  exerciseName: string;
  reps: string;
  weight: string;
  completed: boolean;
}

interface AIExercise {
  name: string;
  sets: number;
  reps: string;
  weightKg?: number;
  bodyweightOnly: boolean;
}

interface WorkoutLoggerProps {
  weightUnit: WeightUnit;
  aiExercises?: AIExercise[];
}

function buildSetsFromAI(exercises: AIExercise[], weightUnit: WeightUnit): SetEntry[] {
  const entries: SetEntry[] = [];
  for (const ex of exercises) {
    for (let s = 0; s < ex.sets; s++) {
      const displayWeight = ex.weightKg
        ? String(Math.round(fromKilograms(ex.weightKg, weightUnit)))
        : "";
      entries.push({
        exerciseName: ex.name,
        reps: ex.reps,
        weight: displayWeight,
        completed: false,
      });
    }
  }
  return entries;
}

export function WorkoutLogger({ weightUnit, aiExercises }: WorkoutLoggerProps) {
  const router = useRouter();
  const [startTime] = useState(() => Date.now());
  const [elapsed, setElapsed] = useState(0);
  const [sets, setSets] = useState<SetEntry[]>(() =>
    aiExercises ? buildSetsFromAI(aiExercises, weightUnit) : []
  );
  const [currentExercise, setCurrentExercise] = useState("");
  const [effort, setEffort] = useState(5);
  const [notes, setNotes] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const timer = setInterval(() => setElapsed(Date.now() - startTime), 1000);
    return () => clearInterval(timer);
  }, [startTime]);

  const formatTime = useCallback((ms: number) => {
    const totalSec = Math.floor(ms / 1000);
    const min = Math.floor(totalSec / 60);
    const sec = totalSec % 60;
    return `${min}:${String(sec).padStart(2, "0")}`;
  }, []);

  const addSet = () => {
    if (!currentExercise.trim()) return;
    setSets((prev) => [
      ...prev,
      { exerciseName: currentExercise.trim(), reps: "", weight: "", completed: false },
    ]);
  };

  const updateSet = (index: number, field: keyof SetEntry, value: string | boolean) => {
    setSets((prev) => prev.map((s, i) => (i === index ? { ...s, [field]: value } : s)));
  };

  const handleComplete = async () => {
    setError(null);
    setSaving(true);
    try {
      await saveWorkout({
        durationSeconds: Math.floor(elapsed / 1000),
        perceivedEffort: effort,
        notes: notes || undefined,
        sets: sets.map((s, i) => {
          const weightNum = parseFloat(s.weight) || 0;
          const weightKg = weightNum > 0 ? toKilograms(weightNum, weightUnit) : undefined;
          return {
            exerciseName: s.exerciseName,
            setIndex: i,
            prescribedReps: s.reps || "0",
            actualReps: parseInt(s.reps) || undefined,
            prescribedWeightKg: weightKg,
            actualWeightKg: weightKg,
            isCompleted: s.completed,
          };
        }),
      });
      router.push("/workouts");
    } catch (error) {
      setError(getErrorMessage(error));
      setSaving(false);
    }
  };

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader
        label="In Progress"
        title="Log Workout"
        action={
          <div className="bg-navy/5 border border-gold/20 rounded-button px-4 py-2">
            <span className="font-mono text-xl text-orange font-bold">{formatTime(elapsed)}</span>
          </div>
        }
      />

      {/* Add Exercise */}
      <Card>
        <SectionHeader label="Exercise" title="Add Set" />
        <div className="flex gap-3 mt-3">
          <Input
            placeholder="Exercise name"
            value={currentExercise}
            onChange={(e) => setCurrentExercise(e.target.value)}
            className="flex-1"
          />
          <Button onClick={addSet} variant="secondary">
            Add
          </Button>
        </div>
      </Card>

      {/* Sets List */}
      {sets.length > 0 && (
        <Card>
          <SectionHeader label="Tracking" title={`Sets (${sets.length})`} />
          <div className="flex flex-col gap-2 mt-3">
            {sets.map((s, i) => (
              <div
                key={i}
                className="flex items-center gap-2 p-3 bg-cream rounded-sm border border-separator/30"
              >
                <input
                  type="checkbox"
                  checked={s.completed}
                  onChange={(e) => updateSet(i, "completed", e.target.checked)}
                  className="w-5 h-5 accent-orange"
                />
                <span className="flex-1 text-[13px] font-semibold truncate">{s.exerciseName}</span>
                <input
                  type="number"
                  placeholder="Reps"
                  value={s.reps}
                  onChange={(e) => updateSet(i, "reps", e.target.value)}
                  className="w-16 px-2 py-1.5 text-[13px] bg-card-bg border border-separator rounded-sm text-center font-mono"
                />
                <input
                  type="number"
                  placeholder={weightUnit}
                  value={s.weight}
                  onChange={(e) => updateSet(i, "weight", e.target.value)}
                  className="w-16 px-2 py-1.5 text-[13px] bg-card-bg border border-separator rounded-sm text-center font-mono"
                />
              </div>
            ))}
          </div>
        </Card>
      )}

      {/* Effort & Notes */}
      <Card>
        <SectionHeader label="Recovery" title="How did it feel?" />
        <div className="flex items-center gap-3 mt-3 mb-3">
          <input
            type="range"
            min={1}
            max={10}
            value={effort}
            onChange={(e) => setEffort(parseInt(e.target.value))}
            className="flex-1 accent-orange"
          />
          <div className="w-10 h-10 rounded-full bg-orange/10 border border-orange/20 flex items-center justify-center">
            <span className="font-bold font-mono text-orange">{effort}</span>
          </div>
        </div>
        <Input
          placeholder="Notes (optional)"
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
        />
      </Card>

      {error && <FormAlert message={error} />}

      <Button fullWidth onClick={handleComplete} disabled={saving || sets.length === 0}>
        {saving ? "Saving..." : "Complete Workout"}
      </Button>
    </div>
  );
}
