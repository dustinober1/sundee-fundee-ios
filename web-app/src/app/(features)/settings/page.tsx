import { Card } from "@/components/ui/card";
import { getAuthUser } from "@/lib/firestore";
import { getUserProfile, getSubscription } from "./actions";
import { ProfileForm } from "./profile-form";
import { SubscriptionCard } from "./subscription-card";
import { SignOutButton } from "./sign-out-button";
import { redirect } from "next/navigation";

export default async function SettingsPage() {
  const [user, profile, subscription] = await Promise.all([
    getAuthUser(),
    getUserProfile(),
    getSubscription(),
  ]);

  if (!user) redirect("/sign-in");

  const tier = ((subscription as Record<string, unknown>)?.tier as "free" | "plus" | "premium") ?? "free";

  return (
    <div className="flex flex-col gap-8 pt-6">
      <div className="pl-2">
        <p className="text-gold font-mono text-[10px] tracking-[0.3em] uppercase mb-1">Account</p>
        <h1 className="text-3xl">Settings</h1>
      </div>

      <Card>
        <h2 className="mb-spacing-sm">Profile</h2>
        <ProfileForm
          initialName={(profile as Record<string, unknown>)?.name as string ?? user.name ?? ""}
          initialWeightUnit={(profile as Record<string, unknown>)?.weightUnit as string ?? "lb"}
          initialExperience={(profile as Record<string, unknown>)?.experienceLevel as string ?? "beginner"}
          initialGoal={(profile as Record<string, unknown>)?.primaryGoal as string ?? "strength"}
        />
      </Card>

      <SubscriptionCard tier={tier} />

      <Card>
        <h2 className="mb-spacing-sm">Account</h2>
        <p className="text-text-secondary text-[13px] mb-spacing-sm">{user.email}</p>
        <SignOutButton />
      </Card>
    </div>
  );
}
