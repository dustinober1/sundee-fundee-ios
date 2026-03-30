import { Card } from "@/components/ui/card";
import { PageHeader, SectionHeader, ArtDecoRuleSmall } from "@/components/ui/art-deco";
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
    <div className="flex flex-col gap-8 pt-4">
      <PageHeader label="Account" title="Settings" />

      <Card>
        <SectionHeader label="Personal" title="Profile" />
        <div className="mt-4">
          <ProfileForm
            initialName={(profile as Record<string, unknown>)?.name as string ?? user.name ?? ""}
            initialWeightUnit={(profile as Record<string, unknown>)?.weightUnit as string ?? "lb"}
            initialExperience={(profile as Record<string, unknown>)?.experienceLevel as string ?? "beginner"}
            initialGoal={(profile as Record<string, unknown>)?.primaryGoal as string ?? "strength"}
          />
        </div>
      </Card>

      <ArtDecoRuleSmall className="text-gold/30 mx-auto" />

      <SubscriptionCard tier={tier} />

      <Card>
        <SectionHeader label="Security" title="Account" />
        <div className="mt-3">
          <p className="text-text-secondary text-[13px] mb-4 font-mono">{user.email}</p>
          <SignOutButton />
        </div>
      </Card>
    </div>
  );
}
