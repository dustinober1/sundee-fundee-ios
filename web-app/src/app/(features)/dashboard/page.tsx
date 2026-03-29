import { Card } from "@/components/ui/card";

export default function DashboardPage() {
  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Dashboard</h1>
      <Card>
        <h2 className="mb-spacing-sm">Welcome to Sundee Fundee</h2>
        <p className="text-text-secondary text-[13px]">
          Your personalized strength training companion.
        </p>
      </Card>
    </div>
  );
}
