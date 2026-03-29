import { Card } from "@/components/ui/card";
import { generateProgram, type ProgramTemplate, exerciseValueToString } from "@/lib/domain";
import { EnrollButton } from "./enroll-button";

const VALID_TEMPLATES = ["strength", "hypertrophy", "fullBody", "linear", "dup", "block"];

export default async function ProgramDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  if (!VALID_TEMPLATES.includes(id)) {
    return <p>Program not found.</p>;
  }

  const program = generateProgram(id as ProgramTemplate, id.charAt(0).toUpperCase() + id.slice(1));

  return (
    <div className="flex flex-col gap-spacing-md">
      <div>
        <h1>{program.name}</h1>
        <p className="text-text-secondary">{program.description}</p>
      </div>

      <div className="grid grid-cols-3 gap-spacing-sm">
        <Card className="text-center">
          <p className="text-xl font-bold text-orange">{program.durationWeeks}</p>
          <p className="text-[11px] text-text-secondary">Weeks</p>
        </Card>
        <Card className="text-center">
          <p className="text-xl font-bold text-orange">{program.sessionsPerWeek}</p>
          <p className="text-[11px] text-text-secondary">Days/Week</p>
        </Card>
        <Card className="text-center">
          <p className="text-xl font-bold text-orange">{program.difficulty.charAt(0).toUpperCase()}</p>
          <p className="text-[11px] text-text-secondary">{program.difficulty}</p>
        </Card>
      </div>

      <EnrollButton programId={id} />

      {program.phases.length > 0 && (
        <Card>
          <h2 className="mb-spacing-sm">Phases</h2>
          {program.phases.map((phase) => (
            <div key={phase.id} className="mb-spacing-xs">
              <p className="font-medium text-[14px]">{phase.name}</p>
              <p className="text-text-secondary text-[12px]">{phase.goal}</p>
            </div>
          ))}
        </Card>
      )}

      <Card>
        <h2 className="mb-spacing-sm">Week 1 Preview</h2>
        {program.weeks[0]?.sessions.map((session) => (
          <div key={session.sessionId} className="mb-spacing-md last:mb-0">
            <p className="font-medium text-[14px] mb-spacing-xs">{session.sessionName}</p>
            {session.exercises.map((ex, i) => (
              <div key={i} className="flex justify-between text-[13px] py-spacing-xs border-b border-separator/50 last:border-0">
                <span>{ex.exercise}</span>
                <span className="text-text-secondary">
                  {exerciseValueToString(ex.sets)}×{exerciseValueToString(ex.reps)}
                  {ex.percent1RM ? ` @ ${Math.round(ex.percent1RM * 100)}%` : ""}
                </span>
              </div>
            ))}
          </div>
        ))}
      </Card>
    </div>
  );
}
