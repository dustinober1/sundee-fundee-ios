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
    <main className="max-w-[720px] mx-auto">
      <Link href="/" className="inline-block mb-spacing-lg font-semibold text-orange hover:underline">
        &larr; Home
      </Link>
      <h1 className="text-4xl mb-1">Privacy Policy</h1>
      <p className="text-orange font-semibold mb-spacing-xl">Sundee Fundee</p>

      <p className="mb-spacing-lg">
        This privacy policy covers <strong>Sundee Fundee</strong>, a cycle-aware strength training
        application. Your privacy matters to us. This policy explains what data our app collects,
        how we use it, and your rights.
      </p>

      <Section title="1. Data We Collect">
        <h3 className="text-[17px] mt-spacing-md mb-spacing-sm font-semibold">Account Information</h3>
        <p>
          When you sign in with Google or Apple, we receive your provider-supplied user identifier
          and display name. We do not receive or store your email address unless you choose to share it.
        </p>

        <h3 className="text-[17px] mt-spacing-md mb-spacing-sm font-semibold">Health &amp; Fitness Data</h3>
        <p>
          Sundee Fundee stores workout logs, one-rep maxes, cycle tracking data, and injury
          profiles in your account. This data is not shared with any external service.
        </p>

        <h3 className="text-[17px] mt-spacing-md mb-spacing-sm font-semibold">Cloud Data</h3>
        <p className="mb-spacing-sm">If you are signed in, your data syncs to the cloud:</p>
        <ul className="list-disc pl-6">
          <li>Workout logs, one-rep maxes, benchmark scores, injury records, and program enrollment (private — accessible only to you)</li>
          <li>Program content and workout templates (public — no personal information)</li>
        </ul>

        <h3 className="text-[17px] mt-spacing-md mb-spacing-sm font-semibold">AI-Generated Content</h3>
        <p>
          When you use AI workout generation, your fitness data (1RM values, injury profiles, energy
          level, cycle phase) is sent to our AI service to generate personalized workouts. This data
          is used only for workout generation and is not stored beyond the request.
        </p>
      </Section>

      <Section title="2. How We Use Your Data">
        <ul className="list-disc pl-6">
          <li>Track your workouts, progress, and personal records</li>
          <li>Provide cycle-phase-aware training recommendations</li>
          <li>Modify exercises based on injury status</li>
          <li>Generate personalized AI workouts</li>
          <li>Sync your data across your devices</li>
        </ul>
      </Section>

      <Section title="3. Data We Do NOT Collect">
        <ul className="list-disc pl-6">
          <li>We do not collect analytics or usage tracking data</li>
          <li>We do not use advertising SDKs or ad tracking</li>
          <li>We do not sell, rent, or share your personal data with third parties</li>
        </ul>
      </Section>

      <Section title="4. Data Storage &amp; Security">
        <p>
          All personal data is stored in our secure cloud database (Cloudflare D1). Data is
          encrypted in transit via HTTPS. We do not share personal data with third parties.
        </p>
      </Section>

      <Section title="5. Data Retention &amp; Deletion">
        <p className="mb-spacing-sm">
          Your data remains in your account for as long as you use the app.
          To delete your data:
        </p>
        <ul className="list-disc pl-6">
          <li>
            Open the app &rarr; Settings &rarr;{" "}
            <strong>Delete Account</strong>. This permanently removes your profile, workout history,
            injury records, maxes, benchmark scores, and all other personal data.
          </li>
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
          Our app is not directed at children under 17. We do not knowingly collect personal
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
