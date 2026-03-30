import { Card } from "@/components/ui/card";
import { PageHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
import { DeleteRecordButton } from "@/components/ui/delete-record-button";
import { deleteMax, getMaxes } from "./actions";
import { AddMaxForm } from "./add-max-form";
import { getUserProfile } from "../settings/actions";
import { formatWeightWithUnit, WeightUnit } from "@/lib/domain";

export default async function MaxesPage() {
  const [maxes, profile] = await Promise.all([
    getMaxes(),
    getUserProfile(),
  ]);
  const weightUnit = (profile?.weightUnit as WeightUnit) ?? WeightUnit.pounds;

  // Group by exercise
  const grouped = new Map<string, typeof maxes>();
  for (const m of maxes) {
    const group = grouped.get(m.exerciseId) ?? [];
    group.push(m);
    grouped.set(m.exerciseId, group);
  }

  return (
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader label="Strength" title="Max Lifts" />

      <AddMaxForm weightUnit={weightUnit} />

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      {grouped.size === 0 ? (
        <Card>
          <div className="text-center py-8">
            <div className="text-gold/30 mb-4">
              <svg className="w-12 h-12 mx-auto" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
              </svg>
            </div>
            <p className="text-text-secondary text-[13px]">
              No maxes logged yet. Add your first one-rep max above.
            </p>
          </div>
        </Card>
      ) : (
        Array.from(grouped.entries()).map(([exercise, records]) => (
          <Card key={exercise} className="hover:shadow-md transition-shadow">
            <div className="flex justify-between items-center mb-2">
              <h2 className="text-[15px]">{exercise}</h2>
              <span className="text-orange font-bold font-mono text-lg">{formatWeightWithUnit(records[0].weightKg, weightUnit)}</span>
            </div>
            <div className="border-t border-separator/50 pt-2">
              <div className="flex flex-col gap-1.5">
                {records.slice(0, 3).map((r) => (
                  <div key={r.id} className="flex items-start justify-between gap-3 text-[12px] text-text-secondary">
                    <div>
                      <span>{r.date ? new Date(r.date).toLocaleDateString() : ""}</span>
                      <span className="ml-2 font-mono">{formatWeightWithUnit(r.weightKg, weightUnit)}{r.isEstimated ? " (est)" : ""}</span>
                    </div>
                    <DeleteRecordButton action={deleteMax} recordId={r.id} noun="Max" />
                  </div>
                ))}
              </div>
            </div>
          </Card>
        ))
      )}
    </div>
  );
}
