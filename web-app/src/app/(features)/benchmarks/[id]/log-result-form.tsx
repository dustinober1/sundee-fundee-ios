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
  const [notes, setNotes] = useState("");
  const [saving, setSaving] = useState(false);

  const label = scoringType === "time" ? "Time (seconds)"
    : scoringType === "weight" ? "Weight (kg)"
    : scoringType === "reps" ? "Reps"
    : "Score";

  return (
    <Card>
      <h2 className="mb-spacing-sm">Log Result</h2>
      <div className="flex flex-col gap-spacing-sm">
        <Input label={label} type="number" value={score} onChange={(e) => setScore(e.target.value)} />
        <Input label="Notes" value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="Optional" />
        <Button
          fullWidth
          disabled={saving || !score}
          onClick={async () => {
            setSaving(true);
            try {
              await logBenchmarkResult({ definitionId, scoreValue: parseFloat(score), notes: notes || undefined });
              setScore(""); setNotes("");
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
