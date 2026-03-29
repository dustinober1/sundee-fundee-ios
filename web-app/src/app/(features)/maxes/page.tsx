import { Card } from "@/components/ui/card";

export default function MaxesPage() {
  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Max Lifts</h1>
      <Card>
        <p className="text-text-secondary text-[13px]">Track your one-rep maxes here.</p>
      </Card>
    </div>
  );
}
