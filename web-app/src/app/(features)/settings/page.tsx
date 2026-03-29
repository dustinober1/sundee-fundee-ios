import { Card } from "@/components/ui/card";

export default function SettingsPage() {
  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Settings</h1>
      <Card>
        <p className="text-text-secondary text-[13px]">Profile and app settings.</p>
      </Card>
    </div>
  );
}
