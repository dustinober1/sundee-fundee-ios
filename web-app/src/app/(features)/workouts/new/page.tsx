"use client";

import { useState, useEffect, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { saveWorkout } from "../actions";

interface SetEntry {
  exerciseName: string;
  reps: string;
  weight: string;
  completed: boolean;
}

export default function NewWorkoutPage() {
  const router = useRouter();
  const [startTime] = useState(() => Date.now());
  const [elapsed, setElapsed] = useState(0);
  const [sets, setSets] = useState<SetEntry[]>([]);
  const [currentExercise, setCurrentExercise] = useState("");
  const [effort, setEffort] = useState(5);
  const [notes, setNotes] = useState("");
  const [saving, setSaving] = useState(false);

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
    setSaving(true);
    try {
      await saveWorkout({
        durationSeconds: Math.floor(elapsed / 1000),
        perceivedEffort: effort,
        notes: notes || undefined,
        sets: sets.map((s, i) => ({
          exerciseName: s.exerciseName,
          setIndex: i,
          prescribedReps: s.reps || "0",
          actualReps: parseInt(s.reps) || undefined,
          prescribedWeightKg: parseFloat(s.weight) || undefined,
          actualWeightKg: parseFloat(s.weight) || undefined,
          isCompleted: s.completed,
        })),
      });
      router.push("/workouts");
    } catch {
      setSaving(false);
    }
  };

  return (
    <div className="flex flex-col gap-8 pt-6">
      <div className="flex items-center justify-between">
        <div className="pl-2">
          <p className="text-gold font-mono text-[10px] tracking-[0.3em] uppercase mb-1">In Progress</p>
          <h1 className="text-3xl">Log Workout</h1>
        </div>
        <span className="font-mono text-xl text-orange">{formatTime(elapsed)}</span>
      </div>

      {/* Add Exercise */}
      <Card>
        <h2 className="mb-spacing-sm">Add Set</h2>
        <div className="flex gap-spacing-sm mb-spacing-sm">
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
          <h2 className="mb-spacing-sm">Sets ({sets.length})</h2>
          <div className="flex flex-col gap-spacing-sm">
            {sets.map((s, i) => (
              <div
                key={i}
                className="flex items-center gap-spacing-xs p-spacing-xs bg-cream rounded-sm"
              >
                <input
                  type="checkbox"
                  checked={s.completed}
                  onChange={(e) => updateSet(i, "completed", e.target.checked)}
                  className="w-5 h-5 accent-orange"
                />
                <span className="flex-1 text-[13px] font-medium truncate">{s.exerciseName}</span>
                <input
                  type="number"
                  placeholder="Reps"
                  value={s.reps}
                  onChange={(e) => updateSet(i, "reps", e.target.value)}
                  className="w-16 px-2 py-1 text-[13px] bg-card-bg border border-separator rounded-sm text-center"
                />
                <input
                  type="number"
                  placeholder="kg"
                  value={s.weight}
                  onChange={(e) => updateSet(i, "weight", e.target.value)}
                  className="w-16 px-2 py-1 text-[13px] bg-card-bg border border-separator rounded-sm text-center"
                />
              </div>
            ))}
          </div>
        </Card>
      )}

      {/* Effort & Notes */}
      <Card>
        <h2 className="mb-spacing-sm">How did it feel?</h2>
        <div className="flex items-center gap-spacing-sm mb-spacing-sm">
          <input
            type="range"
            min={1}
            max={10}
            value={effort}
            onChange={(e) => setEffort(parseInt(e.target.value))}
            className="flex-1 accent-orange"
          />
          <span className="font-bold text-orange w-8 text-center">{effort}</span>
        </div>
        <Input
          placeholder="Notes (optional)"
          value={notes}
          onChange={(e) => setNotes(e.target.value)}
        />
      </Card>

      <Button fullWidth onClick={handleComplete} disabled={saving || sets.length === 0}>
        {saving ? "Saving..." : "Complete Workout"}
      </Button>
    </div>
  );
}
