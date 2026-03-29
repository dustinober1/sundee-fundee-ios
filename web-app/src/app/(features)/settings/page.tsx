import { Card } from "@/components/ui/card";
import { auth } from "@/lib/auth";
import { getUserProfile, getSubscription } from "./actions";
import { tierDisplayName } from "@/lib/domain";
import { ProfileForm } from "./profile-form";
import { SubscriptionCard } from "./subscription-card";
import { SignOutButton } from "./sign-out-button";

export default async function SettingsPage() {
  const [session, profile, subscription] = await Promise.all([
    auth(),
    getUserProfile(),
    getSubscription(),
  ]);

  const tier = (subscription?.tier as "free" | "plus" | "premium") ?? "free";

  return (
    <div className="flex flex-col gap-spacing-md">
      <h1>Settings</h1>

      <Card>
        <h2 className="mb-spacing-sm">Profile</h2>
        <ProfileForm
          initialName={profile?.name ?? session?.user?.name ?? ""}
          initialWeightUnit={profile?.weightUnit ?? "lb"}
          initialExperience={profile?.experienceLevel ?? "beginner"}
          initialGoal={profile?.primaryGoal ?? "strength"}
        />
      </Card>

      <SubscriptionCard tier={tier} />

      <Card>
        <h2 className="mb-spacing-sm">Account</h2>
        <p className="text-text-secondary text-[13px] mb-spacing-sm">{session?.user?.email}</p>
        <SignOutButton />
      </Card>
    </div>
  );
}
