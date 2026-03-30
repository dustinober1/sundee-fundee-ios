"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { FormAlert } from "@/components/ui/form-alert";
import { addMax } from "./actions";
import { estimate1RM, toKilograms } from "@/lib/domain";
import { getErrorMessage } from "@/lib/client-errors";

export function AddMaxForm({ weightUnit = "lb" }: { weightUnit?: string }) {
  const router = useRouter();
  const [exercise, setExercise] = useState("");
  const [weight, setWeight] = useState("");
  const [reps, setReps] = useState("1");
  const [saving, setSaving] = useState(false);
  const [open, setOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const weightNum = parseFloat(weight) || 0;
  const repsNum = parseInt(reps) || 1;
  const estimated1RM = repsNum > 1 ? estimate1RM(weightNum, repsNum) : weightNum;
  const isEstimated = repsNum > 1;

  const handleSubmit = async () => {
    if (!exercise.trim() || !weightNum) return;
    setError(null);
    setSaving(true);
    try {
      await addMax({ exerciseId: exercise.trim(), weightKg: toKilograms(estimated1RM, weightUnit), isEstimated });
      setExercise(""); setWeight(""); setReps("1"); setOpen(false);
      router.refresh();
    } catch (error) {
      setError(getErrorMessage(error));
    } finally {
      setSaving(false);
    }
  };

  if (!open) {
    return (
      <Button fullWidth onClick={() => setOpen(true)} variant="secondary">
        + Add Max
      </Button>
    );
  }

  return (
    <Card>
      <h2 className="mb-spacing-sm">Log Max</h2>
      <div className="flex flex-col gap-spacing-sm">
        <Input label="Exercise" value={exercise} onChange={(e) => setExercise(e.target.value)} placeholder="e.g. Back Squat" />
        <div className="grid grid-cols-2 gap-spacing-sm">
          <Input label={`Weight (${weightUnit})`} type="number" value={weight} onChange={(e) => setWeight(e.target.value)} />
          <Input label="Reps" type="number" value={reps} onChange={(e) => setReps(e.target.value)} />
        </div>
        {isEstimated && weightNum > 0 && (
          <p className="text-[13px] text-text-secondary">
            Estimated 1RM: <span className="text-orange font-medium">{Math.round(estimated1RM * 10) / 10} {weightUnit}</span> (Epley)
          </p>
        )}
        {error && <FormAlert message={error} />}
        <div className="flex gap-spacing-sm">
          <Button variant="secondary" onClick={() => setOpen(false)} className="flex-1">Cancel</Button>
          <Button onClick={handleSubmit} disabled={saving || !exercise || !weightNum} className="flex-1">
            {saving ? "Saving..." : "Save"}
          </Button>
        </div>
      </div>
    </Card>
  );
}
