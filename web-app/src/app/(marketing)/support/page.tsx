import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Support — Sundee Fundee",
  description: "Get help with Sundee Fundee. FAQs and contact information.",
  openGraph: {
    title: "Support — Sundee Fundee",
    description: "Get help with Sundee Fundee. FAQs and contact information.",
  },
};

export default function SupportPage() {
  return (
    <main className="max-w-[720px] mx-auto">
      <Link href="/" className="inline-block mb-spacing-lg font-semibold text-orange hover:underline">
        &larr; Home
      </Link>
      <h1 className="text-4xl mb-1">Support</h1>
      <p className="text-orange font-semibold mb-spacing-xl">Sundee Fundee</p>

      <p className="mb-spacing-lg">
        We&apos;re here to help you get the most out of Sundee Fundee. Check below for answers to
        common questions, or reach out directly.
      </p>

      <h2 className="text-xl mt-spacing-xl mb-spacing-md border-b-2 border-orange pb-1">
        Frequently Asked Questions
      </h2>

      <Faq question="How do I sync my data across devices?">
        Sign in with Google or Apple to enable cloud sync. Your workouts, maxes, and progress will
        automatically sync across all your devices.
      </Faq>

      <Faq question="How does cycle-aware training work?">
        Enable cycle tracking in Settings, then log your cycle data. Sundee Fundee uses this to
        recommend training intensity and volume adjustments based on your current phase.
      </Faq>

      <Faq question="How do AI workouts work?">
        The AI workout generator uses your 1RM data, injury profiles, energy level, and cycle phase
        to create personalized training sessions. Free users get on-device generation, while Plus
        and Premium subscribers get cloud-powered AI workouts.
      </Faq>

      <Faq question="How do I report an injury?">
        Go to your settings and use the injury management feature. The app will automatically modify
        exercises and adjust loads to accommodate your injury.
      </Faq>

      <Faq question="How do I delete my account?">
        Open the app, go to <strong>Settings</strong>, and tap{" "}
        <strong>Delete Account</strong>. This permanently removes your profile, workout history,
        injury records, maxes, benchmark scores, and all other personal data. You can also email us at{" "}
        <a href="mailto:support@sundeefundee.com" className="text-orange font-semibold hover:underline">
          support@sundeefundee.com
        </a>{" "}
        for assistance.
      </Faq>

      <h2 className="text-xl mt-spacing-xl mb-spacing-md border-b-2 border-orange pb-1">
        Contact Us
      </h2>

      <div className="bg-card-bg border-2 border-navy rounded-card p-spacing-lg mt-spacing-md">
        <p className="mb-spacing-sm">For bug reports, feature requests, or any questions:</p>
        <a
          href="mailto:support@sundeefundee.com"
          className="text-[17px] text-orange font-semibold hover:underline"
        >
          support@sundeefundee.com
        </a>
        <p className="mt-spacing-sm">We typically respond within 48 hours.</p>
      </div>
    </main>
  );
}

function Faq({ question, children }: { question: string; children: React.ReactNode }) {
  return (
    <div className="mb-spacing-md">
      <p className="font-bold mb-spacing-xs">{question}</p>
      <p>{children}</p>
    </div>
  );
}
