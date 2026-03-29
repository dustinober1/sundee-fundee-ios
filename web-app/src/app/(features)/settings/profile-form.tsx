"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { updateProfile } from "./actions";

export function ProfileForm({ initialName, initialWeightUnit, initialExperience, initialGoal }: {
  initialName: string; initialWeightUnit: string; initialExperience: string; initialGoal: string;
}) {
  const router = useRouter();
  const [name, setName] = useState(initialName);
  const [weightUnit, setWeightUnit] = useState(initialWeightUnit);
  const [experience, setExperience] = useState(initialExperience);
  const [goal, setGoal] = useState(initialGoal);
  const [saving, setSaving] = useState(false);

  return (
    <div className="flex flex-col gap-spacing-sm">
      <Input label="Name" value={name} onChange={(e) => setName(e.target.value)} />
      <div>
        <label className="text-[13px] font-medium text-navy block mb-spacing-xs">Weight Unit</label>
        <select value={weightUnit} onChange={(e) => setWeightUnit(e.target.value)}
          className="w-full px-spacing-sm py-spacing-sm bg-card-bg border border-separator rounded-sm text-navy text-[15px]">
          <option value="lb">Pounds (lb)</option>
          <option value="kg">Kilograms (kg)</option>
        </select>
      </div>
      <div>
        <label className="text-[13px] font-medium text-navy block mb-spacing-xs">Experience</label>
        <select value={experience} onChange={(e) => setExperience(e.target.value)}
          className="w-full px-spacing-sm py-spacing-sm bg-card-bg border border-separator rounded-sm text-navy text-[15px]">
          <option value="beginner">Beginner</option>
          <option value="intermediate">Intermediate</option>
          <option value="advanced">Advanced</option>
        </select>
      </div>
      <div>
        <label className="text-[13px] font-medium text-navy block mb-spacing-xs">Primary Goal</label>
        <select value={goal} onChange={(e) => setGoal(e.target.value)}
          className="w-full px-spacing-sm py-spacing-sm bg-card-bg border border-separator rounded-sm text-navy text-[15px]">
          <option value="strength">Strength</option>
          <option value="hypertrophy">Hypertrophy</option>
          <option value="endurance">Endurance</option>
          <option value="weight_loss">Weight Loss</option>
        </select>
      </div>
      <Button disabled={saving} onClick={async () => {
        setSaving(true);
        try {
          await updateProfile({ name, weightUnit, experienceLevel: experience, primaryGoal: goal });
          router.refresh();
        } finally { setSaving(false); }
      }}>
        {saving ? "Saving..." : "Save Profile"}
      </Button>
    </div>
  );
}
