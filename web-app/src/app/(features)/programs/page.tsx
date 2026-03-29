import { Card } from "@/components/ui/card";
import Link from "next/link";
import { getEnrolledPrograms } from "./actions";

const TEMPLATES = [
  { id: "strength", name: "Strength", desc: "4 weeks, 3x/week — build raw strength", difficulty: "Intermediate" },
  { id: "hypertrophy", name: "Hypertrophy", desc: "6 weeks, 4x/week — maximize muscle growth", difficulty: "Intermediate" },
  { id: "fullBody", name: "Full Body", desc: "4 weeks, 3x/week — balanced whole-body training", difficulty: "Beginner" },
  { id: "linear", name: "Linear Periodization", desc: "6 weeks, 3x/week — progressive overload", difficulty: "Intermediate" },
  { id: "dup", name: "DUP", desc: "4 weeks, 3x/week — daily undulating periodization", difficulty: "Intermediate" },
  { id: "block", name: "Block Periodization", desc: "9 weeks, 3x/week — accumulation → peaking", difficulty: "Advanced" },
];

export default async function ProgramsPage() {
  const enrolled = await getEnrolledPrograms();

  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Programs</h1>

      {enrolled.length > 0 && (
        <div className="flex flex-col gap-spacing-sm">
          <h2>Active Programs</h2>
          {enrolled.filter(p => p.status === "active").map((p) => (
            <Card key={p.id}>
              <div className="flex justify-between items-center">
                <div>
                  <p className="font-medium">{p.programId}</p>
                  <p className="text-text-secondary text-[13px]">Week {p.currentWeek} · Day {p.currentDay}</p>
                </div>
                <span className="text-[12px] bg-orange/10 text-orange px-2 py-1 rounded-sm font-medium">Active</span>
              </div>
            </Card>
          ))}
        </div>
      )}

      <h2>Program Templates</h2>
      <div className="flex flex-col gap-spacing-sm">
        {TEMPLATES.map((t) => (
          <Link key={t.id} href={`/programs/${t.id}`}>
            <Card className="hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start">
                <div>
                  <p className="font-medium">{t.name}</p>
                  <p className="text-text-secondary text-[13px]">{t.desc}</p>
                </div>
                <span className="text-[11px] bg-navy/5 text-navy px-2 py-0.5 rounded-sm">{t.difficulty}</span>
              </div>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}
