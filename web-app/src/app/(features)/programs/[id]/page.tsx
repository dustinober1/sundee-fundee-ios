import { Card } from "@/components/ui/card";
import { PageHeader, StatCard, SectionHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
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
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader
        label="Program"
        title={program.name}
        subtitle={program.description}
      />

      <div className="grid grid-cols-3 gap-3">
        <StatCard value={program.durationWeeks} label="Weeks" />
        <StatCard value={program.sessionsPerWeek} label="Days/Wk" />
        <StatCard value={program.difficulty.charAt(0).toUpperCase()} label={program.difficulty} />
      </div>

      <EnrollButton programId={id} />

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      {program.phases.length > 0 && (
        <Card>
          <SectionHeader label="Structure" title="Phases" />
          <div className="mt-3 flex flex-col gap-3">
            {program.phases.map((phase, i) => (
              <div key={phase.id} className="flex items-start gap-3">
                <div className="flex-shrink-0 w-7 h-7 rounded-full bg-gold/10 border border-gold/20 flex items-center justify-center">
                  <span className="text-[11px] font-mono font-bold text-gold">{i + 1}</span>
                </div>
                <div>
                  <p className="font-semibold text-[14px]">{phase.name}</p>
                  <p className="text-text-secondary text-[12px]">{phase.goal}</p>
                </div>
              </div>
            ))}
          </div>
        </Card>
      )}

      <Card>
        <SectionHeader label="Preview" title="Week 1" />
        <div className="mt-3">
          {program.weeks[0]?.sessions.map((session) => (
            <div key={session.sessionId} className="mb-5 last:mb-0">
              <p className="font-heading font-semibold text-[14px] mb-2 pb-1 border-b border-gold/15">
                {session.sessionName}
              </p>
              {session.exercises.map((ex, i) => (
                <div key={i} className="flex justify-between text-[13px] py-2 border-b border-separator/30 last:border-0">
                  <span>{ex.exercise}</span>
                  <span className="text-text-secondary font-mono">
                    {exerciseValueToString(ex.sets)}×{exerciseValueToString(ex.reps)}
                    {ex.percent1RM ? ` @ ${Math.round(ex.percent1RM * 100)}%` : ""}
                  </span>
                </div>
              ))}
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}
