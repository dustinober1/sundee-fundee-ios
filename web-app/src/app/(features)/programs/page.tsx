import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import { DeleteRecordButton } from "@/components/ui/delete-record-button";
import Link from "next/link";
import { getEnrolledPrograms, unenrollProgram, getPublishedPrograms, getProgramById } from "./actions";

const DIFFICULTY_STYLES: Record<string, string> = {
  Beginner: "bg-gold/10 text-gold border border-gold/20",
  Intermediate: "bg-orange/10 text-orange border border-orange/20",
  Advanced: "bg-navy/10 text-navy border border-navy/20",
};

export const dynamic = "force-dynamic";

export default async function ProgramsPage() {
  try {
    const [rawEnrolled, templates] = await Promise.all([
      getEnrolledPrograms(),
      getPublishedPrograms(),
    ]);

    // Enrich active enrollments with program name + current session
    const enrolled = await Promise.all(
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      rawEnrolled.map(async (e: any) => {
        const program = await getProgramById(e.programId);
        const weekIndex = (e.currentWeek ?? 1) - 1;
        const dayIndex = (e.currentDay ?? 1) - 1;
        const session = program?.weeks?.[weekIndex]?.sessions?.[dayIndex];
        return {
          ...e,
          programName: program?.name ?? e.programId,
          currentSessionName: session?.sessionName ?? null,
        };
      })
    );

    return (
      <div className="flex flex-col gap-8 pt-4">
        <PageHeader label="Training" title="Programs" />

        {enrolled.length > 0 && (
          <div className="flex flex-col gap-3">
            <SectionHeader label="In Progress" title="Active Programs" />
            {enrolled
              .filter((p) => p.status === "active")
              .map((p) => (
                <Card key={p.id} className="border-l-[3px] border-l-orange">
                  <div className="flex justify-between items-center">
                    <div>
                      <p className="font-heading font-semibold">{p.programName}</p>
                      <p className="text-text-secondary text-[13px] mt-0.5">
                        Week {p.currentWeek} · Day {p.currentDay}
                        {p.currentSessionName && <> · {p.currentSessionName}</>}
                      </p>
                    </div>
                    <span className="text-[11px] bg-orange/10 text-orange px-2.5 py-1 rounded-full font-semibold font-mono tracking-wider uppercase">
                      Active
                    </span>
                  </div>
                  <div className="mt-3 flex items-center justify-between">
                    <Link
                      href={`/workouts/new?enrollment=${p.id}`}
                      className="bg-orange text-cream rounded-button px-5 py-2.5 text-[13px] font-semibold hover:opacity-90 transition-opacity shadow-md shadow-orange/20"
                    >
                      Start Workout
                    </Link>
                    <DeleteRecordButton action={unenrollProgram} recordId={p.id} noun="Program" />
                  </div>
                </Card>
              ))}
          </div>
        )}

        <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

        <div className="flex flex-col gap-3">
          <SectionHeader label="Browse" title="Program Templates" />
          {templates.length === 0 ? (
            <p className="text-center text-text-secondary py-8 text-sm italic">
              No published programs available at the moment.
            </p>
          ) : (
            templates.map((t) => (
              <Link key={t.id} href={`/programs/${t.id}`}>
                <Card className="hover:shadow-md hover:border-gold/20 border border-transparent transition-all">
                  <div className="flex justify-between items-start">
                    <div>
                      <p className="font-heading font-semibold">{t.name}</p>
                      <p className="text-text-secondary text-[13px] mt-0.5">{t.description}</p>
                    </div>
                    <span
                      className={`text-[10px] px-2.5 py-1 rounded-full font-mono tracking-wider uppercase whitespace-nowrap ${
                        DIFFICULTY_STYLES[t.difficulty] ?? ""
                      }`}
                    >
                      {t.difficulty}
                    </span>
                  </div>
                </Card>
              </Link>
            ))
          )}
        </div>
      </div>
    );
  } catch (error) {
    console.error("Error in ProgramsPage:", error);
    return (
      <div className="p-8 text-center">
        <PageHeader label="Error" title="Something went wrong" />
        <p className="text-text-secondary mt-4">
          We couldn&apos;t load the programs. Please try again later.
        </p>
        <pre className="mt-4 p-4 bg-navy/5 rounded text-left text-xs overflow-auto">
          {error instanceof Error ? error.message : String(error)}
        </pre>
      </div>
    );
  }
}
