import { Card } from "@/components/ui/card";

export default function BenchmarksPage() {
  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Benchmarks</h1>
      <Card>
        <p className="text-text-secondary text-[13px]">Track benchmark workouts here.</p>
      </Card>
    </div>
  );
}
