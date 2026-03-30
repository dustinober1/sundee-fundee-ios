import { Card } from "@/components/ui/card";
import { ArtDecoRule, SectionLabel, SectionHeader } from "@/components/ui/art-deco";
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
      <Link href="/" className="text-gold font-mono text-[11px] tracking-[0.2em] uppercase hover:text-orange transition-colors">
        &larr; Home
      </Link>

      <div className="mt-6 mb-2">
        <SectionLabel className="mb-2">Help Center</SectionLabel>
        <h1 className="!text-4xl !font-bold tracking-tight mb-1">Support</h1>
        <p className="text-gold font-mono text-[11px] tracking-[0.2em] uppercase">Sundee Fundee</p>
      </div>
      <ArtDecoRule className="text-gold/30 my-6" />

      <p className="mb-8 text-text-secondary leading-relaxed">
        We&apos;re here to help you get the most out of Sundee Fundee. Check below for answers to
        common questions, or reach out directly.
      </p>

      <SectionHeader label="Common Questions" title="FAQ" />

      <div className="flex flex-col gap-4 mt-4">
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
      </div>

      <div className="mt-10">
        <SectionHeader label="Get in Touch" title="Contact Us" />
      </div>

      <Card className="mt-4 border-l-[3px] border-l-gold">
        <p className="mb-3 text-text-secondary">For bug reports, feature requests, or any questions:</p>
        <a
          href="mailto:support@sundeefundee.com"
          className="text-[17px] text-orange font-heading font-bold hover:underline"
        >
          support@sundeefundee.com
        </a>
        <p className="mt-3 text-text-secondary text-[13px] font-mono">We typically respond within 48 hours.</p>
      </Card>
    </main>
  );
}

function Faq({ question, children }: { question: string; children: React.ReactNode }) {
  return (
    <Card className="hover:shadow-md transition-shadow">
      <p className="font-heading font-semibold mb-2">{question}</p>
      <p className="text-text-secondary text-[14px] leading-relaxed">{children}</p>
    </Card>
  );
}
