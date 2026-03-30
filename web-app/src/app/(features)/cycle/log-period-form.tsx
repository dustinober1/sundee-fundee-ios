"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import { logPeriod } from "./actions";

export function LogPeriodForm() {
  const router = useRouter();
  const [date, setDate] = useState(() => new Date().toISOString().split("T")[0]);
  const [saving, setSaving] = useState(false);

  return (
    <Card>
      <h2 className="mb-spacing-sm">Log Period</h2>
      <div className="flex gap-spacing-sm">
        <Input type="date" value={date} onChange={(e) => setDate(e.target.value)} className="flex-1" />
        <Button
          disabled={saving}
          onClick={async () => {
            setSaving(true);
            try {
              await logPeriod({ startDate: date, flowLevel: "medium" });
              router.refresh();
            } finally { setSaving(false); }
          }}
        >
          {saving ? "..." : "Log"}
        </Button>
      </div>
    </Card>
  );
}
