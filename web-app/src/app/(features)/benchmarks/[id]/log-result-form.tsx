"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { logBenchmarkResult } from "../actions";

export function LogResultForm({ definitionId, scoringType }: { definitionId: string; scoringType: string }) {
  const router = useRouter();
  const [score, setScore] = useState("");
  const [hours, setHours] = useState("");
  const [minutes, setMinutes] = useState("");
  const [seconds, setSeconds] = useState("");
  const [notes, setNotes] = useState("");
  const [saving, setSaving] = useState(false);

  const isTime = scoringType === "time";

  const label = scoringType === "weight" ? "Weight (kg)"
    : scoringType === "reps" ? "Reps"
    : "Score";

  const timeValue = (parseInt(hours || "0") * 3600) + (parseInt(minutes || "0") * 60) + parseInt(seconds || "0");
  const hasTimeValue = hours || minutes || seconds;
  const canSubmit = isTime ? hasTimeValue && timeValue > 0 : score;

  return (
    <Card>
      <h2 className="mb-spacing-sm">Log Result</h2>
      <div className="flex flex-col gap-spacing-sm">
        {isTime ? (
          <div className="flex flex-col gap-1">
            <label className="text-[11px] font-mono uppercase tracking-wider text-text-secondary">Time</label>
            <div className="flex gap-2 items-center">
              <Input
                type="number"
                value={hours}
                onChange={(e) => setHours(e.target.value.replace(/[^0-9]/g, ""))}
                placeholder="0"
                min="0"
                className="w-16 text-center"
              />
              <span className="text-text-secondary font-mono text-sm">h</span>
              <Input
                type="number"
                value={minutes}
                onChange={(e) => setMinutes(e.target.value.replace(/[^0-9]/g, "").slice(0, 2))}
                placeholder="0"
                min="0"
                max="59"
                className="w-16 text-center"
              />
              <span className="text-text-secondary font-mono text-sm">m</span>
              <Input
                type="number"
                value={seconds}
                onChange={(e) => setSeconds(e.target.value.replace(/[^0-9]/g, "").slice(0, 2))}
                placeholder="0"
                min="0"
                max="59"
                className="w-16 text-center"
              />
              <span className="text-text-secondary font-mono text-sm">s</span>
            </div>
          </div>
        ) : (
          <Input label={label} type="number" value={score} onChange={(e) => setScore(e.target.value)} />
        )}
        <Input label="Notes" value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Optional" />
        <Button
          fullWidth
          disabled={saving || !canSubmit}
          onClick={async () => {
            setSaving(true);
            try {
              const scoreValue = isTime ? timeValue : parseFloat(score);
              await logBenchmarkResult({ definitionId, scoreValue, notes: notes || undefined });
              setScore(""); setNotes(""); setHours(""); setMinutes(""); setSeconds("");
              router.refresh();
            } finally { setSaving(false); }
          }}
        >
          {saving ? "Saving..." : "Log Result"}
        </Button>
      </div>
    </Card>
  );
}
