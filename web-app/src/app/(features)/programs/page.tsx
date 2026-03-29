import { Card } from "@/components/ui/card";

export default function ProgramsPage() {
  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Programs</h1>
      <Card>
        <p className="text-text-secondary text-[13px]">Browse training programs.</p>
      </Card>
    </div>
  );
}
