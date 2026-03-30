"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { FormAlert } from "@/components/ui/form-alert";
import { updateProfile } from "./actions";
import { getErrorMessage } from "@/lib/client-errors";

const EXPERIENCE_OPTIONS = [
  { value: "beginner", label: "Beginner", desc: "Less than 1 year" },
  { value: "intermediate", label: "Intermediate", desc: "1\u20133 years" },
  { value: "advanced", label: "Advanced", desc: "3+ years" },
] as const;

const GOAL_OPTIONS = [
  { value: "strength", label: "Strength", desc: "Max lifts & power" },
  { value: "hypertrophy", label: "Hypertrophy", desc: "Muscle growth" },
  { value: "endurance", label: "Endurance", desc: "Stamina & conditioning" },
  { value: "weight_loss", label: "Weight Loss", desc: "Fat loss & toning" },
] as const;

export function ProfileForm({ initialName, initialWeightUnit, initialExperience, initialGoal }: {
  initialName: string; initialWeightUnit: string; initialExperience: string; initialGoal: string;
}) {
  const router = useRouter();
  const [name, setName] = useState(initialName);
  const [weightUnit, setWeightUnit] = useState(initialWeightUnit);
  const [experience, setExperience] = useState(initialExperience);
  const [goal, setGoal] = useState(initialGoal);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const hasChanges =
    name !== initialName ||
    weightUnit !== initialWeightUnit ||
    experience !== initialExperience ||
    goal !== initialGoal;

  async function handleSave() {
    setError(null);
    setSaving(true);
    try {
      await updateProfile({ name, weightUnit, experienceLevel: experience, primaryGoal: goal });
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
      router.refresh();
    } catch (error) {
      setError(getErrorMessage(error));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="flex flex-col gap-5">
      <Input label="Display Name" value={name} onChange={(e) => setName(e.target.value)} placeholder="Your name" />

      {/* Weight Unit Toggle */}
      <div className="flex flex-col gap-spacing-xs">
        <label className="text-[13px] font-medium text-navy">Weight Unit</label>
        <div className="grid grid-cols-2 gap-0 rounded-sm overflow-hidden border border-separator">
          <button
            type="button"
            onClick={() => setWeightUnit("lb")}
            className={`py-2.5 text-[14px] font-medium transition-all ${
              weightUnit === "lb"
                ? "bg-navy text-cream"
                : "bg-card-bg text-text-secondary hover:bg-separator/30"
            }`}
          >
            Pounds (lb)
          </button>
          <button
            type="button"
            onClick={() => setWeightUnit("kg")}
            className={`py-2.5 text-[14px] font-medium transition-all border-l border-separator ${
              weightUnit === "kg"
                ? "bg-navy text-cream"
                : "bg-card-bg text-text-secondary hover:bg-separator/30"
            }`}
          >
            Kilograms (kg)
          </button>
        </div>
      </div>

      {/* Experience Level */}
      <div className="flex flex-col gap-spacing-xs">
        <label className="text-[13px] font-medium text-navy">Experience Level</label>
        <div className="grid grid-cols-3 gap-2">
          {EXPERIENCE_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => setExperience(opt.value)}
              className={`flex flex-col items-center gap-0.5 py-3 px-2 rounded-sm border text-center transition-all ${
                experience === opt.value
                  ? "border-orange bg-orange/5 ring-1 ring-orange/30"
                  : "border-separator bg-card-bg hover:border-gold/30"
              }`}
            >
              <span className={`text-[13px] font-medium ${experience === opt.value ? "text-navy" : "text-navy/70"}`}>
                {opt.label}
              </span>
              <span className="text-[10px] text-text-secondary">{opt.desc}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Primary Goal */}
      <div className="flex flex-col gap-spacing-xs">
        <label className="text-[13px] font-medium text-navy">Primary Goal</label>
        <div className="grid grid-cols-2 gap-2">
          {GOAL_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => setGoal(opt.value)}
              className={`flex flex-col items-start gap-0.5 py-3 px-3 rounded-sm border text-left transition-all ${
                goal === opt.value
                  ? "border-orange bg-orange/5 ring-1 ring-orange/30"
                  : "border-separator bg-card-bg hover:border-gold/30"
              }`}
            >
              <span className={`text-[13px] font-medium ${goal === opt.value ? "text-navy" : "text-navy/70"}`}>
                {opt.label}
              </span>
              <span className="text-[10px] text-text-secondary">{opt.desc}</span>
            </button>
          ))}
        </div>
      </div>

      {error && <FormAlert message={error} />}

      <Button
        disabled={saving || !hasChanges}
        onClick={handleSave}
        fullWidth
        className={saved ? "!bg-navy" : ""}
      >
        {saving ? "Saving\u2026" : saved ? "Saved" : "Save Changes"}
      </Button>
    </div>
  );
}
