"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import type { WorkoutFocus, EnergyLevel, EquipmentAccess, GeneratedExercise } from "@/lib/domain";

type Step = "questionnaire" | "loading" | "preview";

const FOCUS_OPTIONS: { value: WorkoutFocus; label: string }[] = [
  { value: "upper_body", label: "Upper Body" },
  { value: "lower_body", label: "Lower Body" },
  { value: "full_body", label: "Full Body" },
  { value: "push", label: "Push" },
  { value: "pull", label: "Pull" },
  { value: "core", label: "Core" },
  { value: "conditioning", label: "Conditioning" },
];

const ENERGY_OPTIONS: { value: EnergyLevel; label: string; icon: string }[] = [
  { value: "low", label: "Low", icon: "🪫" },
  { value: "medium", label: "Medium", icon: "🔋" },
  { value: "high", label: "High", icon: "⚡" },
];

const EQUIPMENT_OPTIONS: { value: EquipmentAccess; label: string }[] = [
  { value: "full_gym", label: "Full Gym" },
  { value: "home_dumbbells", label: "Home (Dumbbells)" },
  { value: "bodyweight_only", label: "Bodyweight Only" },
  { value: "outdoor", label: "Outdoor" },
];

export default function AIWorkoutPage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>("questionnaire");
  const [time, setTime] = useState(30);
  const [focus, setFocus] = useState<WorkoutFocus>("full_body");
  const [energy, setEnergy] = useState<EnergyLevel>("medium");
  const [equipment, setEquipment] = useState<EquipmentAccess>("full_gym");
  const [workout, setWorkout] = useState<{ coachingSummary: string; exercises: GeneratedExercise[] } | null>(null);
  const [error, setError] = useState<string | null>(null);

  const generate = async () => {
    setStep("loading");
    setError(null);
    try {
      const res = await fetch("/api/ai/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ time, focus, energy, equipment }),
      });
      if (!res.ok) throw new Error("Generation failed");
      const data = await res.json() as { coachingSummary: string; exercises: GeneratedExercise[] };
      setWorkout(data);
      setStep("preview");
    } catch {
      setError("Failed to generate workout. Please try again.");
      setStep("questionnaire");
    }
  };

  if (step === "loading") {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-spacing-md">
        <div className="w-12 h-12 border-4 border-orange border-t-transparent rounded-full animate-spin" />
        <p className="text-text-secondary">Generating your workout...</p>
      </div>
    );
  }

  if (step === "preview" && workout) {
    return (
      <div className="flex flex-col gap-spacing-md">
        <h1>Your Workout</h1>
        <Card>
          <p className="text-[14px] text-text-secondary">{workout.coachingSummary}</p>
        </Card>
        {workout.exercises.map((ex, i) => (
          <Card key={i}>
            <div className="flex justify-between items-start">
              <div>
                <p className="font-medium">{ex.name}</p>
                <p className="text-text-secondary text-[13px]">
                  {ex.sets} sets × {ex.reps} reps
                  {ex.weightKg ? ` @ ${ex.weightKg} kg` : ""}
                </p>
              </div>
              {ex.restMinutes && (
                <span className="text-[12px] text-text-secondary">{ex.restMinutes}m rest</span>
              )}
            </div>
            {ex.notes && <p className="text-[12px] text-text-secondary mt-spacing-xs">{ex.notes}</p>}
          </Card>
        ))}
        <div className="flex gap-spacing-sm">
          <Button variant="secondary" fullWidth onClick={() => setStep("questionnaire")}>
            Regenerate
          </Button>
          <Button fullWidth onClick={() => router.push("/workouts/new")}>
            Start Workout
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>AI Workout</h1>

      {error && (
        <Card>
          <p className="text-error text-[13px]">{error}</p>
        </Card>
      )}

      <Card>
        <h2 className="mb-spacing-sm">Time (minutes)</h2>
        <div className="flex items-center gap-spacing-sm">
          <input type="range" min={15} max={90} step={5} value={time} onChange={(e) => setTime(parseInt(e.target.value))}
            className="flex-1 accent-orange" />
          <span className="font-bold text-orange w-12 text-center">{time}</span>
        </div>
      </Card>

      <Card>
        <h2 className="mb-spacing-sm">Focus</h2>
        <div className="grid grid-cols-2 gap-spacing-xs">
          {FOCUS_OPTIONS.map((o) => (
            <button key={o.value} onClick={() => setFocus(o.value)}
              className={`px-spacing-sm py-spacing-xs rounded-sm text-[13px] font-medium border transition-colors ${focus === o.value ? "bg-orange text-cream border-orange" : "bg-card-bg text-navy border-separator hover:border-navy"}`}>
              {o.label}
            </button>
          ))}
        </div>
      </Card>

      <Card>
        <h2 className="mb-spacing-sm">Energy Level</h2>
        <div className="grid grid-cols-3 gap-spacing-xs">
          {ENERGY_OPTIONS.map((o) => (
            <button key={o.value} onClick={() => setEnergy(o.value)}
              className={`px-spacing-sm py-spacing-sm rounded-sm text-[13px] font-medium border text-center transition-colors ${energy === o.value ? "bg-orange text-cream border-orange" : "bg-card-bg text-navy border-separator hover:border-navy"}`}>
              {o.icon} {o.label}
            </button>
          ))}
        </div>
      </Card>

      <Card>
        <h2 className="mb-spacing-sm">Equipment</h2>
        <div className="grid grid-cols-2 gap-spacing-xs">
          {EQUIPMENT_OPTIONS.map((o) => (
            <button key={o.value} onClick={() => setEquipment(o.value)}
              className={`px-spacing-sm py-spacing-xs rounded-sm text-[13px] font-medium border transition-colors ${equipment === o.value ? "bg-orange text-cream border-orange" : "bg-card-bg text-navy border-separator hover:border-navy"}`}>
              {o.label}
            </button>
          ))}
        </div>
      </Card>

      <Button fullWidth onClick={generate}>
        Generate Workout
      </Button>
    </div>
  );
}
