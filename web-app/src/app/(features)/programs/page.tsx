import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import { DeleteRecordButton } from "@/components/ui/delete-record-button";
import Link from "next/link";
import { getEnrolledPrograms, unenrollProgram, getPublishedPrograms } from "./actions";

const DIFFICULTY_STYLES: Record<string, string> = {
  Beginner: "bg-gold/10 text-gold border border-gold/20",
  Intermediate: "bg-orange/10 text-orange border border-orange/20",
  Advanced: "bg-navy/10 text-navy border border-navy/20",
};

export const dynamic = "force-dynamic";

export default async function ProgramsPage() {
  const [enrolled, templates] = await Promise.all([
    getEnrolledPrograms(),
    getPublishedPrograms(),
  ]);

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
                    <p className="font-heading font-semibold">{p.programId}</p>
                    <p className="text-text-secondary text-[13px] mt-0.5">
                      Week {p.currentWeek} · Day {p.currentDay}
                    </p>
                  </div>
                  <span className="text-[11px] bg-orange/10 text-orange px-2.5 py-1 rounded-full font-semibold font-mono tracking-wider uppercase">
                    Active
                  </span>
                </div>
                <div className="mt-3 flex justify-end">
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
}
