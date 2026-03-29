import { Card } from "@/components/ui/card";
import { getMaxes } from "./actions";
import { AddMaxForm } from "./add-max-form";

export default async function MaxesPage() {
  const maxes = await getMaxes();

  // Group by exercise
  const grouped = new Map<string, typeof maxes>();
  for (const m of maxes) {
    const group = grouped.get(m.exerciseId) ?? [];
    group.push(m);
    grouped.set(m.exerciseId, group);
  }

  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Max Lifts</h1>

      <AddMaxForm />

      {grouped.size === 0 ? (
        <Card>
          <p className="text-text-secondary text-[13px] text-center py-spacing-md">
            No maxes logged yet. Add your first one-rep max above.
          </p>
        </Card>
      ) : (
        Array.from(grouped.entries()).map(([exercise, records]) => (
          <Card key={exercise}>
            <div className="flex justify-between items-center mb-spacing-xs">
              <h2 className="text-[15px]">{exercise}</h2>
              <span className="text-orange font-bold">{records[0].weightKg} kg</span>
            </div>
            <div className="flex flex-col gap-spacing-xs">
              {records.slice(0, 3).map((r) => (
                <div key={r.id} className="flex justify-between text-[12px] text-text-secondary">
                  <span>{r.date ? new Date(r.date).toLocaleDateString() : ""}</span>
                  <span>{r.weightKg} kg {r.isEstimated ? "(est)" : ""}</span>
                </div>
              ))}
            </div>
          </Card>
        ))
      )}
    </div>
  );
}
