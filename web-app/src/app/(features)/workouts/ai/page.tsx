"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall, StatCard } from "@/components/ui/art-deco";
import type { WorkoutFocus, EnergyLevel, EquipmentAccess } from "@/lib/domain";
import type { AIWorkoutResponse } from "@/lib/ai-generation";
import { CyclePhaseBanner } from "@/components/ui/cycle-phase-banner";
import { CycleAdjustmentToggle } from "@/components/ui/cycle-adjustment-toggle";
import { getPhaseAdjustmentSummary, formatWeightWithUnit, WeightUnit, totalEstimatedMinutes, extractMuscleGroups } from "@/lib/domain";
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
      const text = await res.text();
      let data: AIWorkoutResponse | { error?: string };
      try {
        data = JSON.parse(text);
      } catch {
        throw new Error(`Server returned invalid JSON (${res.status}): ${text.substring(0, 200)}`);
      }
      if (!res.ok) {
        throw new Error("error" in data && typeof data.error === "string" ? data.error : "Generation failed");
      }
      const workoutResponse = data as AIWorkoutResponse;
      setWorkout(workoutResponse);
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
    const estMinutes = totalEstimatedMinutes(workout.exercises);
    const muscleGroups = extractMuscleGroups(workout.exercises);
    const exerciseCount = workout.exercises.length;

    return (
      <div className="flex flex-col gap-8 pt-4">
        <PageHeader
          label="AI Session"
          title="Your Workout"
          subtitle={workout.coachingSummary}
        />

        <div className="grid grid-cols-3 gap-3">
          <StatCard value={`~${estMinutes}`} label="Minutes" />
          <StatCard value={exerciseCount} label="Exercises" />
          <StatCard value={workout.exercises.reduce((s, e) => s + e.sets, 0)} label="Total Sets" />
        </div>

        {muscleGroups.length > 0 && (
          <div className="flex flex-wrap gap-1.5">
            {muscleGroups.map((g) => (
              <span key={g} className="text-[11px] bg-gold/10 text-gold border border-gold/20 px-2.5 py-1 rounded-full">
                {g}
              </span>
            ))}
          </div>
        )}

        <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

        <Card>
          <SectionHeader label="Exercises" title="Workout Plan" />
          <div className="mt-3">
            {workout.exercises.map((ex, i) => (
              <div key={i} className="flex justify-between text-[13px] py-2.5 border-b border-separator/30 last:border-0">
                <div className="flex items-start gap-3 flex-1 min-w-0">
                  <div className="flex-shrink-0 w-6 h-6 rounded-full bg-gold/10 border border-gold/20 flex items-center justify-center mt-0.5">
                    <span className="text-[10px] font-mono font-bold text-gold">{i + 1}</span>
                  </div>
                  <div className="min-w-0">
                    <span className="font-semibold block">{ex.name}</span>
                    {ex.notes && (
                      <span className="text-[11px] text-text-secondary block mt-0.5">{ex.notes}</span>
                    )}
                  </div>
                </div>
                <div className="text-right flex-shrink-0 ml-3">
                  <span className="text-text-secondary font-mono">
                    {ex.sets}×{ex.reps}
                    {ex.weightKg ? ` @ ${formatWeightWithUnit(ex.weightKg, userWeightUnit)}` : ""}
                  </span>
                  {ex.restMinutes && (
                    <div className="text-[10px] text-gold mt-0.5">{ex.restMinutes}m rest</div>
                  )}
                </div>
              </div>
            ))}
          </div>
        </Card>

        <p className="text-[11px] text-text-secondary text-center">
          {workout.usage.generatedToday}/{workout.usage.dailyCloudLimit} used today · {workout.usage.remainingCloudGenerations} remaining
        </p>

        <div className="flex gap-3">
          <Button variant="secondary" fullWidth onClick={() => setStep("questionnaire")}>
            Regenerate
          </Button>
          <Button fullWidth onClick={() => {
            const encoded = encodeURIComponent(JSON.stringify(workout.exercises));
            router.push(`/workouts/new?ai=${encoded}`);
          }}>
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
