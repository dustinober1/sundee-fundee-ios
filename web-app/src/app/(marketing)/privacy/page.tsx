import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy — Sundee Fundee",
  description: "How Sundee Fundee collects, uses, and protects your data.",
  openGraph: {
    title: "Privacy Policy — Sundee Fundee",
    description: "How Sundee Fundee collects, uses, and protects your data.",
  },
};

export default function PrivacyPage() {
  return (
    <main className="max-w-[720px] mx-auto px-spacing-md py-spacing-xl">
      <Link href="/" className="inline-block mb-spacing-lg font-semibold text-orange hover:underline">
        &larr; Home
      </Link>
      <h1 className="text-4xl mb-1">Privacy Policy</h1>
      <p className="text-orange font-semibold mb-spacing-xl">Sundee Fundee Apps</p>

      <p className="mb-spacing-lg">
        This privacy policy covers all applications published by Sundee Fundee, including{" "}
        <strong>Sundee Fundee</strong> (strength training) and{" "}
        <strong>Sundee Fundee Rucking Club</strong> (rucking &amp; fitness tracking). Your privacy
        matters to us. This policy explains what data our apps collect, how we use it, and your
        rights.
      </p>

      <Section title="1. Data We Collect">
        <h3 className="text-[17px] mt-spacing-md mb-spacing-sm font-semibold">Account Information</h3>
        <p>
          When you sign in with Apple, we receive your Apple-provided user identifier. We do not
          receive or store your email address unless you choose to share it.
        </p>

        <h3 className="text-[17px] mt-spacing-md mb-spacing-sm font-semibold">Health &amp; Fitness Data</h3>

        <AppScope title="Sundee Fundee (Strength Training)">
          <p>
            Sundee Fundee stores workout logs, one-rep maxes, cycle tracking data, and injury
            profiles locally on your device and in your private iCloud account. This data does not
            use Apple HealthKit and is not shared with any external service.
          </p>
        </AppScope>

        <AppScope title="Sundee Fundee Rucking Club">
          <p className="mb-spacing-sm">
            With your explicit permission, Sundee Fundee Rucking Club reads and writes the following
            Apple HealthKit data:
          </p>
          <ul className="list-disc pl-6 mb-spacing-sm">
            <li><strong>Workout data</strong> — completed rucks are saved as hiking workouts to Apple Health</li>
            <li><strong>Heart rate data</strong> — read during active rucks on Apple Watch for live metrics</li>
            <li><strong>Active calories</strong> — read during active rucks on Apple Watch</li>
          </ul>
          <p className="font-bold">
            HealthKit data is never transmitted to external servers, never sold, and never used for
            advertising or marketing purposes.
          </p>
        </AppScope>

        <h3 className="text-[17px] mt-spacing-md mb-spacing-sm font-semibold">Location Data</h3>
        <p className="mb-spacing-sm">
          Sundee Fundee Rucking Club collects GPS location data during active rucks to track your
          route, distance, and pace. Location data is:
        </p>
        <ul className="list-disc pl-6">
          <li>Collected only while you are actively tracking a ruck</li>
          <li>Stored locally on your device and in your private iCloud account</li>
          <li>Never transmitted to external servers or shared with third parties</li>
          <li>Filtered for accuracy (readings with horizontal accuracy greater than 20 meters are discarded)</li>
        </ul>

        <h3 className="text-[17px] mt-spacing-md mb-spacing-sm font-semibold">Cloud Data</h3>
        <p className="mb-spacing-sm">If you are signed in with Apple, certain data syncs via iCloud (CloudKit):</p>

        <AppScope title="Sundee Fundee (Strength Training)">
          <ul className="list-disc pl-6">
            <li>Workout logs, one-rep maxes, benchmark scores, injury records, and program enrollment (CloudKit Private Database — accessible only to you)</li>
            <li>Program content and workout templates (CloudKit Public Database — no personal information)</li>
          </ul>
        </AppScope>

        <AppScope title="Sundee Fundee Rucking Club">
          <ul className="list-disc pl-6">
            <li>Ruck logs, user profile, and badges (CloudKit Private Database — accessible only to you)</li>
            <li>Club membership, leaderboard entries, and event RSVPs (CloudKit Public Database — visible to other club members)</li>
          </ul>
        </AppScope>

        <h3 className="text-[17px] mt-spacing-md mb-spacing-sm font-semibold">AI-Generated Content</h3>
        <p>
          If you use the AI Workout Builder in Sundee Fundee, personalized workouts are generated{" "}
          <strong>on your device</strong> using Apple&apos;s on-device language models (Apple
          Intelligence). Your fitness preferences, time availability, equipment access, and active
          injury information are processed locally on your device — no data is sent to external
          servers. Sundee Fundee Rucking Club does not use AI services.
        </p>
      </Section>

      <Section title="2. How We Use Your Data">
        <ul className="list-disc pl-6">
          <li>Track your workouts, rucks, progress, and personal records</li>
          <li>Provide cycle-phase-aware training recommendations (Sundee Fundee)</li>
          <li>Track routes, distance, pace, and elevation during rucks (Rucking Club)</li>
          <li>Enable club membership, leaderboards, and event coordination (Rucking Club)</li>
          <li>Award achievement badges based on your activity (Rucking Club)</li>
          <li>Modify exercises based on injury status (Sundee Fundee)</li>
          <li>Generate personalized AI workouts (Sundee Fundee)</li>
          <li>Sync your data across your devices via iCloud</li>
        </ul>
      </Section>

      <Section title="3. Data We Do NOT Collect">
        <ul className="list-disc pl-6">
          <li>We do not collect analytics or usage tracking data</li>
          <li>We do not use advertising SDKs or ad tracking</li>
          <li>We do not sell, rent, or share your personal data with third parties</li>
          <li>We do not transmit HealthKit data to any external server</li>
          <li>We do not track your location when you are not actively recording a ruck</li>
        </ul>
      </Section>

      <Section title="4. Data Storage &amp; Security">
        <p className="mb-spacing-sm">
          All personal data is stored either locally on your device or in your iCloud account
          (CloudKit). iCloud data is encrypted in transit and at rest by Apple. We do not operate our
          own servers for storing personal user data.
        </p>
        <p>
          Public content (club information, leaderboard rankings, event details) is stored in
          CloudKit Public Database and is visible to other users of the app.
        </p>
      </Section>

      <Section title="5. Data Retention &amp; Deletion">
        <p className="mb-spacing-sm">
          Your data remains on your device and in your iCloud account for as long as you use the app.
          To delete your data:
        </p>
        <ul className="list-disc pl-6">
          <li>
            <strong>Sundee Fundee (Strength Training):</strong> Open the app → Settings →{" "}
            <strong>Delete Account</strong>. This permanently removes your profile, workout history,
            injury records, maxes, benchmark scores, and all other personal data.
          </li>
          <li>
            <strong>Sundee Fundee Rucking Club:</strong> Open the app → More tab →{" "}
            <strong>Delete Account</strong>. This permanently removes your profile, ruck history,
            leaderboard entries, club memberships, and event RSVPs.
          </li>
          <li>Delete the app from your device to remove local data</li>
          <li>Use Settings &gt; Apple ID &gt; iCloud to manage your iCloud data</li>
          <li>
            Contact us at{" "}
            <a href="mailto:support@sundeefundee.com" className="text-orange font-semibold hover:underline">
              support@sundeefundee.com
            </a>{" "}
            for assistance with data deletion
          </li>
        </ul>
        <p className="mt-spacing-sm">
          Account deletion is processed immediately. Once deleted, your data cannot be recovered.
        </p>
      </Section>

      <Section title="6. Children's Privacy">
        <p>
          Our apps are not directed at children under 17. We do not knowingly collect personal
          information from children.
        </p>
      </Section>

      <Section title="7. Changes to This Policy">
        <p>
          We may update this policy from time to time. We will notify you of significant changes
          through the app or by updating the effective date below.
        </p>
      </Section>

      <Section title="8. Contact Us">
        <p>
          If you have questions about this privacy policy or your data, contact us at:{" "}
          <a href="mailto:support@sundeefundee.com" className="text-orange font-semibold hover:underline">
            support@sundeefundee.com
          </a>
        </p>
      </Section>

      <p className="italic text-text-secondary mt-spacing-xl">Effective date: March 25, 2026</p>
    </main>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <>
      <h2 className="text-xl mt-spacing-xl mb-spacing-md border-b-2 border-orange pb-1">{title}</h2>
      {children}
    </>
  );
}

function AppScope({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="bg-card-bg border-2 border-navy rounded-card p-spacing-md mb-spacing-md">
      <h4 className="text-orange font-semibold mb-spacing-sm">{title}</h4>
      {children}
    </div>
  );
}
