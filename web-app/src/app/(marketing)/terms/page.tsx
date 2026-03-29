import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Terms of Use — Sundee Fundee",
  description: "Terms of Use for Sundee Fundee.",
  openGraph: {
    title: "Terms of Use — Sundee Fundee",
    description: "Terms of Use for Sundee Fundee.",
  },
};

export default function TermsPage() {
  return (
    <main className="max-w-[720px] mx-auto">
      <Link href="/" className="inline-block mb-spacing-lg font-semibold text-orange hover:underline">
        &larr; Home
      </Link>
      <h1 className="text-4xl mb-1">Terms of Use</h1>
      <p className="text-orange font-semibold mb-spacing-xl">Sundee Fundee</p>

      <p className="mb-spacing-lg">
        These Terms of Use (&ldquo;Terms&rdquo;) govern your use of <strong>Sundee Fundee</strong>,
        a cycle-aware strength training application (the &ldquo;App&rdquo;). By using the App, you
        agree to these Terms.
      </p>

      <Section title="1. Acceptance of Terms">
        <p>
          By accessing or using the App, you confirm that you are at least 17 years old and agree to
          be bound by these Terms. If you do not agree, do not use the App.
        </p>
      </Section>

      <Section title="2. Description of Services">
        <p>
          Sundee Fundee is a strength training app that provides cycle-aware workout
          recommendations, AI-generated workouts, structured programs, injury management, and
          progress tracking.
        </p>
      </Section>

      <Section title="3. Account &amp; Sign In">
        <p>
          The App uses Google and Apple sign-in for authentication. You are responsible for
          maintaining the security of your account. You may use some features without signing in,
          but certain features (cloud sync, AI workouts, subscriptions) require authentication.
        </p>
      </Section>

      <Section title="4. Health &amp; Fitness Disclaimer">
        <p>
          <strong>The App is not a medical device and does not provide medical advice.</strong> The
          workout recommendations, training suggestions, and fitness data provided by the App are
          for informational and fitness tracking purposes only. Always consult a qualified healthcare
          professional before starting any exercise program. You use the App and follow any training
          recommendations at your own risk.
        </p>
      </Section>

      <Section title="5. User Conduct">
        <p className="mb-spacing-sm">
          You agree to:
        </p>
        <ul className="list-disc pl-6">
          <li>Provide accurate information in your profile</li>
          <li>Not submit fraudulent workout data</li>
          <li>Not attempt to reverse-engineer or exploit the App</li>
          <li>Not use the App for any unlawful purpose</li>
        </ul>
        <p className="mt-spacing-sm">
          We reserve the right to restrict access for users who violate these guidelines.
        </p>
      </Section>

      <Section title="6. Subscriptions &amp; Purchases">
        <p className="mb-spacing-sm">
          The App offers optional subscriptions that unlock premium features. All purchases are
          processed through Stripe and are subject to Stripe&apos;s terms and conditions.
        </p>
        <ul className="list-disc pl-6">
          <li>Subscriptions automatically renew unless cancelled before the end of the current period</li>
          <li>You can manage or cancel subscriptions from the Settings page in the App</li>
          <li>Refunds are handled according to our refund policy</li>
          <li>Free features remain available without a subscription</li>
        </ul>
      </Section>

      <Section title="7. Intellectual Property">
        <p>
          All content, designs, code, and branding in the App are owned by Sundee Fundee and are
          protected by copyright and intellectual property laws. You may not copy, modify, distribute,
          or reverse-engineer any part of the App.
        </p>
      </Section>

      <Section title="8. Data &amp; Privacy">
        <p>
          Your use of the App is also governed by our{" "}
          <Link href="/privacy" className="text-orange font-semibold hover:underline">
            Privacy Policy
          </Link>
          , which describes how we collect, use, and protect your data.
        </p>
      </Section>

      <Section title="9. Third-Party Services">
        <p>
          The App integrates with third-party services including Google and Apple for authentication,
          Stripe for payments, and Cloudflare for hosting and AI services. Your use of these services
          is subject to their respective terms and conditions.
        </p>
      </Section>

      <Section title="10. Limitation of Liability">
        <p className="mb-spacing-sm">
          To the maximum extent permitted by law, Sundee Fundee shall not be liable for any indirect,
          incidental, special, consequential, or punitive damages arising from your use of the App.
          This includes, but is not limited to:
        </p>
        <ul className="list-disc pl-6">
          <li>Injuries sustained during workouts</li>
          <li>Loss of data due to service issues</li>
          <li>Inaccurate workout calculations</li>
          <li>Service interruptions or unavailability</li>
        </ul>
      </Section>

      <Section title="11. Disclaimer of Warranties">
        <p>
          The App is provided &ldquo;as is&rdquo; and &ldquo;as available&rdquo; without warranties
          of any kind, either express or implied. We do not guarantee that the App will be
          error-free, uninterrupted, or that workout calculations will be completely accurate.
        </p>
      </Section>

      <Section title="12. Termination">
        <p>
          We may suspend or terminate your access to the App at any time for violation of these
          Terms. You may stop using the App at any time by deleting your account.
        </p>
      </Section>

      <Section title="13. Changes to These Terms">
        <p>
          We may update these Terms from time to time. Continued use of the App after changes are
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
