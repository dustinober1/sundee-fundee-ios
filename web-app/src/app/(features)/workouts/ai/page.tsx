"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader } from "@/components/ui/art-deco";
import type { WorkoutFocus, EnergyLevel, EquipmentAccess } from "@/lib/domain";
import type { AIWorkoutResponse } from "@/lib/ai-generation";
import { CyclePhaseBanner } from "@/components/ui/cycle-phase-banner";
import { CycleAdjustmentToggle } from "@/components/ui/cycle-adjustment-toggle";
import { getPhaseAdjustmentSummary, formatWeightWithUnit, WeightUnit } from "@/lib/domain";
import type { CyclePhase } from "@/lib/domain";

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

const ENERGY_OPTIONS: { value: EnergyLevel; label: string }[] = [
  { value: "low", label: "Low" },
  { value: "medium", label: "Medium" },
  { value: "high", label: "High" },
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
  const [workout, setWorkout] = useState<AIWorkoutResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [cyclePhase, setCyclePhase] = useState<CyclePhase | null>(null);
  const [cycleDay, setCycleDay] = useState<number>(0);
  const [cycleAdjustments, setCycleAdjustments] = useState(true);
  const [userWeightUnit, setUserWeightUnit] = useState<WeightUnit>(WeightUnit.pounds);

  useEffect(() => {
    async function fetchCycleStatus() {
      try {
        const res = await fetch("/api/cycle/status");
        if (res.ok) {
          const data = await res.json() as { currentPhase: CyclePhase; cycleDay: number } | null;
          if (data) {
            setCyclePhase(data.currentPhase);
            setCycleDay(data.cycleDay);
          }
        }
      } catch {
        // Cycle tracking not available — continue without
      }
    }
    fetchCycleStatus();
  }, []);

  useEffect(() => {
    async function fetchWeightUnit() {
      try {
        const res = await fetch("/api/user/profile");
        if (res.ok) {
          const profile = await res.json();
          setUserWeightUnit((profile.weightUnit as WeightUnit) ?? WeightUnit.pounds);
        }
      } catch {
        // Fallback to lb
        setUserWeightUnit(WeightUnit.pounds);
      }
    }
    fetchWeightUnit();
  }, []);

  const generate = async () => {
    setStep("loading");
    setError(null);
    try {
      const res = await fetch("/api/ai/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          time,
          focus,
          energy,
          equipment,
          cyclePhase: cycleAdjustments ? cyclePhase : undefined,
        }),
      });
      const data = await res.json() as AIWorkoutResponse | { error?: string };
      if (!res.ok) {
        throw new Error("error" in data && typeof data.error === "string" ? data.error : "Generation failed");
      }
      setWorkout(data);
      setStep("preview");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to generate workout. Please try again.");
      setStep("questionnaire");
    }
  };

  if (step === "loading") {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] gap-6">
        <div className="w-14 h-14 border-[3px] border-gold/30 border-t-orange rounded-full animate-spin" />
        <div className="text-center">
          <p className="font-heading font-semibold text-navy">Building your workout</p>
          <p className="text-text-secondary text-[13px] mt-1">Personalizing for your goals...</p>
        </div>
      </div>
    );
  }

  if (step === "preview" && workout) {
    return (
      <div className="flex flex-col gap-8 pt-4">
        <PageHeader label="Generated" title="Your Workout" />

        <Card className="border-l-[3px] border-l-gold">
          <p className="text-[14px] text-text-secondary italic">{workout.coachingSummary}</p>
          <p className="text-[11px] text-text-secondary mt-2">
            {workout.usage.model ? `${workout.usage.model} · ` : ""}
            {workout.usage.generatedToday}/{workout.usage.dailyCloudLimit} used today · {workout.usage.remainingCloudGenerations} left
          </p>
        </Card>

        {workout.exercises.map((ex, i) => (
          <Card key={i} className="hover:shadow-md transition-shadow">
            <div className="flex justify-between items-start">
              <div>
                <p className="font-heading font-semibold">{ex.name}</p>
                <p className="text-text-secondary text-[13px] mt-0.5 font-mono">
                  {ex.sets} sets × {ex.reps} reps
                  {ex.weightKg ? ` @ ${formatWeightWithUnit(ex.weightKg, userWeightUnit)}` : ""}
                </p>
              </div>
              {ex.restMinutes && (
                <span className="text-[11px] text-gold bg-gold/10 border border-gold/20 px-2.5 py-1 rounded-full font-mono">
                  {ex.restMinutes}m rest
                </span>
              )}
            </div>
            {ex.notes && <p className="text-[12px] text-text-secondary mt-2 border-t border-separator/30 pt-2">{ex.notes}</p>}
          </Card>
        ))}

        <div className="flex gap-3">
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
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader label="Smart Training" title="AI Workout" />

      {error && (
        <Card className="border-l-[3px] border-l-error">
          <p className="text-error text-[13px]">{error}</p>
        </Card>
      )}

      {cyclePhase && (
        <>
          <CyclePhaseBanner
            phase={cyclePhase}
            cycleDay={cycleDay}
            adjustmentSummary={getPhaseAdjustmentSummary(cyclePhase)}
          />
          <CycleAdjustmentToggle
            phase={cyclePhase}
            enabled={cycleAdjustments}
            onToggle={() => setCycleAdjustments(!cycleAdjustments)}
          />
        </>
      )}

      <Card>
        <SectionHeader label="Duration" title="Time (minutes)" />
        <div className="flex items-center gap-3 mt-3">
          <input type="range" min={15} max={90} step={5} value={time} onChange={(e) => setTime(parseInt(e.target.value))}
            className="flex-1 accent-orange" />
          <div className="w-12 h-12 rounded-full bg-orange/10 border border-orange/20 flex items-center justify-center">
            <span className="font-bold font-mono text-orange">{time}</span>
          </div>
        </div>
      </Card>

      <Card>
        <SectionHeader label="Target" title="Focus" />
        <div className="grid grid-cols-2 gap-2 mt-3">
          {FOCUS_OPTIONS.map((o) => (
            <button key={o.value} onClick={() => setFocus(o.value)}
              className={`px-3 py-2.5 rounded-button text-[13px] font-medium border transition-all ${
                focus === o.value
                  ? "bg-orange text-cream border-orange shadow-sm shadow-orange/20"
                  : "bg-card-bg text-navy border-gold/15 hover:border-gold/40"
              }`}>
              {o.label}
            </button>
          ))}
        </div>
      </Card>

      <Card>
        <SectionHeader label="How You Feel" title="Energy Level" />
        <div className="grid grid-cols-3 gap-2 mt-3">
          {ENERGY_OPTIONS.map((o) => (
            <button key={o.value} onClick={() => setEnergy(o.value)}
              className={`px-3 py-3 rounded-button text-[13px] font-medium border text-center transition-all ${
                energy === o.value
                  ? "bg-orange text-cream border-orange shadow-sm shadow-orange/20"
                  : "bg-card-bg text-navy border-gold/15 hover:border-gold/40"
              }`}>
              {o.label}
            </button>
          ))}
        </div>
      </Card>

      <Card>
        <SectionHeader label="Setup" title="Equipment" />
        <div className="grid grid-cols-2 gap-2 mt-3">
          {EQUIPMENT_OPTIONS.map((o) => (
            <button key={o.value} onClick={() => setEquipment(o.value)}
              className={`px-3 py-2.5 rounded-button text-[13px] font-medium border transition-all ${
                equipment === o.value
                  ? "bg-orange text-cream border-orange shadow-sm shadow-orange/20"
                  : "bg-card-bg text-navy border-gold/15 hover:border-gold/40"
              }`}>
              {o.label}
            </button>
          ))}
        </div>
      </Card>

      <Button fullWidth onClick={generate} className="shadow-md shadow-orange/20">
        Generate Workout
      </Button>
    </div>
  );
}
