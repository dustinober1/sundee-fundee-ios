import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Terms of Use — Sundee Fundee",
  description: "Terms of Use for Sundee Fundee apps.",
  openGraph: {
    title: "Terms of Use — Sundee Fundee",
    description: "Terms of Use for Sundee Fundee apps.",
  },
};

export default function TermsPage() {
  return (
    <main className="max-w-[720px] mx-auto px-spacing-md py-spacing-xl">
      <Link href="/" className="inline-block mb-spacing-lg font-semibold text-orange hover:underline">
        &larr; Home
      </Link>
      <h1 className="text-4xl mb-1">Terms of Use</h1>
      <p className="text-orange font-semibold mb-spacing-xl">Sundee Fundee Apps</p>

      <p className="mb-spacing-lg">
        These Terms of Use (&ldquo;Terms&rdquo;) govern your use of all applications published by
        Sundee Fundee, including <strong>Sundee Fundee</strong> and{" "}
        <strong>Sundee Fundee Rucking Club</strong> (collectively, the &ldquo;Apps&rdquo;). By
        downloading or using any of our Apps, you agree to these Terms.
      </p>

      <Section title="1. Acceptance of Terms">
        <p>
          By accessing or using our Apps, you confirm that you are at least 17 years old and agree to
          be bound by these Terms. If you do not agree, do not use the Apps.
        </p>
      </Section>

      <Section title="2. Description of Services">
        <p className="mb-spacing-sm">
          <strong>Sundee Fundee</strong> is a strength training app that provides cycle-aware workout
          recommendations, structured programs, injury management, and progress tracking.
        </p>
        <p>
          <strong>Sundee Fundee Rucking Club</strong> is a fitness tracking app for rucking that
          provides GPS route tracking, club membership, leaderboards, events, badges, and Apple Watch
          integration.
        </p>
      </Section>

      <Section title="3. Account &amp; Sign In">
        <p>
          Our Apps use Sign in with Apple for authentication. You are responsible for maintaining the
          security of your Apple ID. You may use some features without signing in, but certain
          features (cloud sync, clubs, leaderboards) require authentication.
        </p>
      </Section>

      <Section title="4. Health &amp; Fitness Disclaimer">
        <p>
          <strong>Our Apps are not medical devices and do not provide medical advice.</strong> The
          workout recommendations, training suggestions, and fitness data provided by our Apps are
          for informational and fitness tracking purposes only. Always consult a qualified healthcare
          professional before starting any exercise program. You use our Apps and follow any training
          recommendations at your own risk.
        </p>
      </Section>

      <Section title="5. User Conduct">
        <p className="mb-spacing-sm">
          When using community features (clubs, leaderboards, events), you agree to:
        </p>
        <ul className="list-disc pl-6">
          <li>Provide accurate information in your user profile</li>
          <li>Not submit fraudulent workout or ruck data</li>
          <li>Not harass, abuse, or harm other users</li>
          <li>Not attempt to manipulate leaderboard rankings</li>
          <li>Not use the Apps for any unlawful purpose</li>
        </ul>
        <p className="mt-spacing-sm">
          We reserve the right to remove content or restrict access for users who violate these
          guidelines.
        </p>
      </Section>

      <Section title="6. Subscriptions &amp; Purchases">
        <p className="mb-spacing-sm">
          Our Apps offer optional subscriptions that unlock premium features. All purchases are
          processed through Apple&apos;s In-App Purchase system and are subject to Apple&apos;s terms
          and conditions.
        </p>
        <ul className="list-disc pl-6">
          <li>Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period</li>
          <li>You can manage or cancel subscriptions in your device&apos;s Settings &gt; Apple ID &gt; Subscriptions</li>
          <li>Refunds are handled by Apple according to their refund policy</li>
          <li>Free features remain available without a subscription</li>
        </ul>
      </Section>

      <Section title="7. Intellectual Property">
        <p>
          All content, designs, code, and branding in our Apps are owned by Sundee Fundee and are
          protected by copyright and intellectual property laws. You may not copy, modify, distribute,
          or reverse-engineer any part of our Apps.
        </p>
      </Section>

      <Section title="8. Data &amp; Privacy">
        <p>
          Your use of our Apps is also governed by our{" "}
          <Link href="/privacy" className="text-orange font-semibold hover:underline">
            Privacy Policy
          </Link>
          , which describes how we collect, use, and protect your data.
        </p>
      </Section>

      <Section title="9. Third-Party Services">
        <p>
          Our Apps integrate with Apple services including iCloud (CloudKit), HealthKit, and StoreKit.
          Your use of these services is subject to Apple&apos;s terms and conditions. We are not
          responsible for the availability or performance of Apple&apos;s services.
        </p>
      </Section>

      <Section title="10. Limitation of Liability">
        <p className="mb-spacing-sm">
          To the maximum extent permitted by law, Sundee Fundee shall not be liable for any indirect,
          incidental, special, consequential, or punitive damages arising from your use of the Apps.
          This includes, but is not limited to:
        </p>
        <ul className="list-disc pl-6">
          <li>Injuries sustained during workouts or rucks</li>
          <li>Loss of data due to device failure or iCloud issues</li>
          <li>Inaccurate GPS, distance, pace, or health data</li>
          <li>Service interruptions or unavailability</li>
        </ul>
      </Section>

      <Section title="11. Disclaimer of Warranties">
        <p>
          Our Apps are provided &ldquo;as is&rdquo; and &ldquo;as available&rdquo; without warranties
          of any kind, either express or implied. We do not guarantee that the Apps will be
          error-free, uninterrupted, or that GPS tracking, health data, or workout calculations will
          be completely accurate.
        </p>
      </Section>

      <Section title="12. Termination">
        <p>
          We may suspend or terminate your access to the Apps at any time for violation of these
          Terms. You may stop using the Apps at any time by deleting them from your devices.
        </p>
      </Section>

      <Section title="13. Changes to These Terms">
        <p>
          We may update these Terms from time to time. Continued use of the Apps after changes are
          posted constitutes acceptance of the updated Terms.
        </p>
      </Section>

      <Section title="14. Governing Law">
        <p>
          These Terms are governed by and construed in accordance with the laws of the United States.
          Any disputes arising from these Terms shall be resolved in the applicable courts.
        </p>
      </Section>

      <Section title="15. Contact Us">
        <p>
          If you have questions about these Terms, contact us at:{" "}
          <a href="mailto:support@sundeefundee.com" className="text-orange font-semibold hover:underline">
            support@sundeefundee.com
          </a>
        </p>
      </Section>

      <p className="italic text-text-secondary mt-spacing-xl">Effective date: March 23, 2026</p>
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
