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
    <div className="flex flex-col gap-8 pt-6">
      <div className="pl-2">
        <p className="text-gold font-mono text-[10px] tracking-[0.3em] uppercase mb-1">Training</p>
        <h1 className="text-3xl">Programs</h1>
      </div>

      {enrolled.length > 0 && (
        <div className="flex flex-col gap-3">
          <p className="text-gold font-mono text-[10px] tracking-[0.2em] uppercase mb-1 pl-2">In Progress</p>
          <h2 className="pl-2">Active Programs</h2>
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

      <div className="flex flex-col gap-3">
        <div className="pl-2">
          <p className="text-gold font-mono text-[10px] tracking-[0.2em] uppercase mb-1">Browse</p>
          <h2>Program Templates</h2>
        </div>
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
