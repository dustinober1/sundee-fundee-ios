import type { Metadata } from "next";
import Link from "next/link";
import { IOSInstallCta } from "@/components/install/ios-install-cta";

export const metadata: Metadata = {
  title: "Sundee Fundee — Train With Your Body, Not Against It",
  description:
    "AI-powered strength training that adapts to your cycle, injuries, and energy. Cycle-synced programming, progressive overload, and personalized workouts — free to start.",
  openGraph: {
    title: "Sundee Fundee — Train With Your Body, Not Against It",
    description:
      "AI-powered strength training that adapts to your cycle, injuries, and energy. Cycle-synced programming, progressive overload, and personalized workouts.",
    url: "https://sundeefundee.com",
  },
  twitter: {
    title: "Sundee Fundee — Train With Your Body, Not Against It",
    description:
      "AI-powered strength training that adapts to your cycle, injuries, and energy.",
  },
};

/* ------------------------------------------------------------------ */
/*  Decorative SVG helpers                                            */
/* ------------------------------------------------------------------ */

function ArtDecoRule({ className = "" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 400 24"
      fill="none"
      className={`w-full max-w-xs mx-auto ${className}`}
      aria-hidden="true"
    >
      <line x1="0" y1="12" x2="160" y2="12" stroke="currentColor" strokeWidth="1" />
      <polygon points="200,2 210,12 200,22 190,12" fill="currentColor" />
      <line x1="240" y1="12" x2="400" y2="12" stroke="currentColor" strokeWidth="1" />
    </svg>
  );
}

function GeometricCorner({ className = "" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 80 80"
      fill="none"
      className={`w-16 h-16 ${className}`}
      aria-hidden="true"
    >
      <path d="M0 0 L80 0 L80 8 L8 8 L8 80 L0 80 Z" fill="currentColor" opacity="0.15" />
      <path d="M0 0 L40 0 L40 4 L4 4 L4 40 L0 40 Z" fill="currentColor" opacity="0.25" />
    </svg>
  );
}

/* ------------------------------------------------------------------ */
/*  Feature data                                                      */
/* ------------------------------------------------------------------ */

const features = [
  {
    title: "Cycle-Synced Training",
    description:
      "Automatically adjusts load, volume, and intensity based on your menstrual cycle phase. Train harder when your body is ready, recover when it needs rest.",
    icon: (
      <svg viewBox="0 0 48 48" className="w-12 h-12" fill="none" stroke="currentColor" strokeWidth="1.5">
        <circle cx="24" cy="24" r="20" />
        <path d="M24 4 C30 16, 30 32, 24 44" />
        <path d="M24 4 C18 16, 18 32, 24 44" />
        <ellipse cx="24" cy="24" rx="20" ry="8" />
      </svg>
    ),
  },
  {
    title: "AI-Powered Workouts",
    description:
      "Generate personalized workouts using your 1RM data, injury history, energy level, and training goals. Every session is built for you.",
    icon: (
      <svg viewBox="0 0 48 48" className="w-12 h-12" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="8" y="6" width="32" height="36" rx="4" />
        <line x1="16" y1="16" x2="32" y2="16" />
        <line x1="16" y1="24" x2="28" y2="24" />
        <line x1="16" y1="32" x2="24" y2="32" />
        <circle cx="36" cy="36" r="8" fill="currentColor" opacity="0.15" />
        <path d="M33 36 L36 39 L40 34" strokeWidth="2" />
      </svg>
    ),
  },
  {
    title: "Injury Adaptation",
    description:
      "Log injuries and pain levels, and your workouts automatically adapt. Smart substitutions keep you training safely around limitations.",
    icon: (
      <svg viewBox="0 0 48 48" className="w-12 h-12" fill="none" stroke="currentColor" strokeWidth="1.5">
        <path d="M24 6 L26 18 L38 18 L28 26 L32 38 L24 30 L16 38 L20 26 L10 18 L22 18 Z" />
      </svg>
    ),
  },
  {
    title: "Progressive Overload",
    description:
      "Track every lift, every PR, every benchmark. Plateau detection and smart deload recommendations keep gains coming.",
    icon: (
      <svg viewBox="0 0 48 48" className="w-12 h-12" fill="none" stroke="currentColor" strokeWidth="1.5">
        <polyline points="6,40 16,28 24,32 32,16 42,8" strokeWidth="2" />
        <circle cx="42" cy="8" r="4" fill="currentColor" opacity="0.3" />
        <line x1="6" y1="44" x2="42" y2="44" />
        <line x1="6" y1="44" x2="6" y2="4" />
      </svg>
    ),
  },
  {
    title: "Program Builder",
    description:
      "Enroll in structured training programs or build your own. Periodization templates, auto-deload weeks, and mesocycle planning built in.",
    icon: (
      <svg viewBox="0 0 48 48" className="w-12 h-12" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="4" y="8" width="40" height="32" rx="4" />
        <line x1="4" y1="16" x2="44" y2="16" />
        <line x1="16" y1="8" x2="16" y2="40" />
        <line x1="28" y1="8" x2="28" y2="40" />
        <rect x="18" y="18" width="8" height="6" rx="1" fill="currentColor" opacity="0.2" />
        <rect x="30" y="24" width="8" height="6" rx="1" fill="currentColor" opacity="0.2" />
        <rect x="6" y="30" width="8" height="6" rx="1" fill="currentColor" opacity="0.2" />
      </svg>
    ),
  },
  {
    title: "Benchmark Tracking",
    description:
      "Track classic benchmarks, custom WODs, and conditioning PRs. See where you stand and how far you've come.",
    icon: (
      <svg viewBox="0 0 48 48" className="w-12 h-12" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="8" y="24" width="8" height="18" rx="2" fill="currentColor" opacity="0.15" />
        <rect x="20" y="14" width="8" height="28" rx="2" fill="currentColor" opacity="0.25" />
        <rect x="32" y="6" width="8" height="36" rx="2" fill="currentColor" opacity="0.35" />
        <path d="M34 2 L36 6 L38 2" strokeWidth="2" />
      </svg>
    ),
  },
] as const;

/* ------------------------------------------------------------------ */
/*  Pricing data                                                      */
/* ------------------------------------------------------------------ */

const tiers = [
  {
    name: "Free",
    price: "$0",
    period: "forever",
    description: "Get started with the essentials",
    features: [
      "5 tracked lifts",
      "1 active injury profile",
      "30-day workout history",
      "On-device AI workouts",
      "Cycle phase tracking",
      "Basic benchmarks",
    ],
    cta: "Get Started",
    highlighted: false,
  },
  {
    name: "Sundee Plus",
    price: "$5",
    period: "/month",
    description: "Unlock the full training toolkit",
    features: [
      "Unlimited lifts & injuries",
      "Full workout history",
      "1 cloud AI workout/day",
      "Custom benchmarks",
      "Pain & effort trends",
      "Program builder",
      "Periodization templates",
      "Auto-deload weeks",
      "Streaks & achievements",
    ],
    cta: "Start Free Trial",
    highlighted: true,
  },
  {
    name: "Sundee Premium",
    price: "$12",
    period: "/month",
    description: "Your personal AI strength coach",
    features: [
      "Everything in Plus",
      "10 cloud AI workouts/day",
      "AI coach memory",
      "Mesocycle planning",
      "Progressive overload engine",
      "Plateau detection",
      "Weekly progress reports",
      "Smart substitutions",
      "Rehab session generator",
      "Data export",
    ],
    cta: "Start Free Trial",
    highlighted: false,
  },
] as const;

/* ------------------------------------------------------------------ */
/*  Steps data                                                        */
/* ------------------------------------------------------------------ */

const steps = [
  {
    number: "01",
    title: "Set Your Foundation",
    description: "Enter your lifts, 1RM data, and any injuries. Optionally enable cycle tracking for phase-aware programming.",
  },
  {
    number: "02",
    title: "Generate & Train",
    description: "Get AI-generated workouts tailored to your body, goals, and how you feel today. Or follow a structured program.",
  },
  {
    number: "03",
    title: "Track & Grow",
    description: "Log your sessions, hit PRs, and watch your strength climb. The AI learns and adapts as you progress.",
  },
] as const;

/* ------------------------------------------------------------------ */
/*  Page                                                              */
/* ------------------------------------------------------------------ */

export default function HomePage() {
  return (
    <main className="overflow-hidden">
      {/* ============================================================ */}
      {/*  NAV                                                         */}
      {/* ============================================================ */}
      <nav className="fixed top-0 left-0 right-0 z-50 bg-cream/80 backdrop-blur-md border-b border-separator/50">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <span className="font-heading text-xl font-bold tracking-tight text-navy">
            Sundee Fundee
          </span>
          <div className="flex items-center gap-4">
            <Link
              href="/sign-in"
              className="text-sm font-medium text-text-secondary hover:text-navy transition-colors"
            >
              Sign In
            </Link>
            <Link
              href="/sign-up"
              className="inline-flex items-center justify-center px-5 py-2 bg-orange text-cream text-sm font-medium rounded-button hover:opacity-90 active:opacity-80 transition-opacity"
            >
              Get Started
            </Link>
          </div>
        </div>
      </nav>

      {/* ============================================================ */}
      {/*  HERO                                                        */}
      {/* ============================================================ */}
      <section className="relative min-h-[90vh] flex flex-col items-center justify-center text-center px-6 pt-24 pb-20">
        {/* Background geometric pattern */}
        <div className="absolute inset-0 overflow-hidden pointer-events-none" aria-hidden="true">
          <div className="absolute top-0 left-0 w-full h-full opacity-[0.03]"
            style={{
              backgroundImage: `repeating-linear-gradient(
                45deg,
                transparent,
                transparent 40px,
                #0d1a40 40px,
                #0d1a40 41px
              )`,
            }}
          />
          {/* Deco corner accents */}
          <GeometricCorner className="absolute top-20 left-4 text-gold sm:left-12" />
          <GeometricCorner className="absolute top-20 right-4 text-gold sm:right-12 -scale-x-100" />
          <GeometricCorner className="absolute bottom-8 left-4 text-gold sm:left-12 -scale-y-100" />
          <GeometricCorner className="absolute bottom-8 right-4 text-gold sm:right-12 scale-x-[-1] scale-y-[-1]" />
        </div>

        <div className="relative z-10 w-full max-w-3xl mx-auto">
          <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-6">
            Strength Training, Reimagined
          </p>
          <h1 className="!text-5xl sm:!text-6xl md:!text-7xl !font-bold !leading-[1.05] tracking-tight mb-6">
            Train With
            <br />
            <span className="text-orange">Your Body,</span>
            <br />
            Not Against It
          </h1>
          <p className="text-lg sm:text-xl text-text-secondary max-w-xl mx-auto mb-10 leading-relaxed">
            AI-powered strength training that adapts to your cycle, your injuries,
            and your energy. Every workout is built for exactly where you are today.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link
              href="/sign-up"
              className="inline-flex items-center justify-center px-8 py-3.5 bg-orange text-cream text-base font-semibold rounded-button hover:opacity-90 active:opacity-80 transition-opacity shadow-lg shadow-orange/20"
            >
              Start Training Free
            </Link>
            <a
              href="#features"
              className="inline-flex items-center justify-center px-8 py-3.5 bg-card-bg text-navy text-base font-medium rounded-button border border-navy/15 hover:bg-separator/30 active:bg-separator/50 transition-colors"
            >
              See How It Works
            </a>
          </div>
          <IOSInstallCta className="mt-6 text-left" />
        </div>

        <ArtDecoRule className="absolute bottom-0 left-1/2 -translate-x-1/2 text-gold/40 max-w-sm" />
      </section>

      {/* ============================================================ */}
      {/*  FEATURES                                                    */}
      {/* ============================================================ */}
      <section id="features" className="relative bg-navy text-cream py-24 px-6">
        {/* Subtle diagonal overlay */}
        <div className="absolute inset-0 opacity-[0.04] pointer-events-none" aria-hidden="true"
          style={{
            backgroundImage: `repeating-linear-gradient(
              -45deg,
              transparent,
              transparent 60px,
              #f4f0df 60px,
              #f4f0df 61px
            )`,
          }}
        />
        <div className="relative z-10 max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-4">
              Everything You Need
            </p>
            <h2 className="!text-3xl sm:!text-4xl !font-bold mb-4">
              Built for Serious Lifters
            </h2>
            <p className="text-cream/60 max-w-lg mx-auto">
              Every feature designed around how your body actually works —
              not a one-size-fits-all template.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((feature) => (
              <div
                key={feature.title}
                className="group p-6 rounded-card bg-cream/[0.04] border border-cream/[0.08] hover:bg-cream/[0.08] hover:border-cream/[0.15] transition-all duration-300"
              >
                <div className="text-gold mb-4">{feature.icon}</div>
                <h3 className="font-heading text-lg font-semibold mb-2">
                  {feature.title}
                </h3>
                <p className="text-cream/50 text-sm leading-relaxed">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ============================================================ */}
      {/*  HOW IT WORKS                                                */}
      {/* ============================================================ */}
      <section className="py-24 px-6">
        <div className="max-w-4xl mx-auto">
          <div className="text-center mb-16">
            <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-4">
              Simple Process
            </p>
            <h2 className="!text-3xl sm:!text-4xl !font-bold mb-4">
              Three Steps to Smarter Training
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {steps.map((step) => (
              <div key={step.number} className="text-center">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-full border-2 border-gold/30 mb-6">
                  <span className="font-mono text-2xl font-bold text-gold">{step.number}</span>
                </div>
                <h3 className="font-heading text-lg font-semibold mb-3">{step.title}</h3>
                <p className="text-text-secondary text-sm leading-relaxed">{step.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ============================================================ */}
      {/*  PRICING                                                     */}
      {/* ============================================================ */}
      <section className="py-24 px-6 bg-card-bg">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-4">
              Pricing
            </p>
            <h2 className="!text-3xl sm:!text-4xl !font-bold mb-4">
              Start Free, Scale When Ready
            </h2>
            <p className="text-text-secondary max-w-lg mx-auto">
              No credit card required. Train with the essentials forever,
              or unlock the full experience.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 items-start">
            {tiers.map((tier) => (
              <div
                key={tier.name}
                className={`relative rounded-lg p-6 ${
                  tier.highlighted
                    ? "bg-navy text-cream border-2 border-gold/40 shadow-xl shadow-navy/10 md:-translate-y-2"
                    : "bg-cream border border-separator"
                }`}
              >
                {tier.highlighted && (
                  <div className="absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 bg-gold text-navy text-xs font-bold uppercase tracking-wider rounded-full">
                    Most Popular
                  </div>
                )}
                <div className="mb-6">
                  <h3 className="font-heading text-lg font-semibold mb-1">{tier.name}</h3>
                  <p className={`text-sm mb-4 ${tier.highlighted ? "text-cream/50" : "text-text-secondary"}`}>
                    {tier.description}
                  </p>
                  <div className="flex items-baseline gap-1">
                    <span className="text-4xl font-bold tracking-tight">{tier.price}</span>
                    <span className={`text-sm ${tier.highlighted ? "text-cream/40" : "text-text-secondary"}`}>
                      {tier.period}
                    </span>
                  </div>
                </div>
                <ul className="space-y-2.5 mb-8">
                  {tier.features.map((feature) => (
                    <li key={feature} className="flex items-start gap-2.5 text-sm">
                      <svg
                        className={`w-4 h-4 mt-0.5 flex-shrink-0 ${
                          tier.highlighted ? "text-gold" : "text-orange"
                        }`}
                        viewBox="0 0 16 16"
                        fill="currentColor"
                      >
                        <path d="M8 1a7 7 0 110 14A7 7 0 018 1zm3.1 4.7a.6.6 0 00-.84-.08L7.4 8.16 5.74 6.76a.6.6 0 10-.77.92l2.08 1.74a.6.6 0 00.81-.04l3.16-3a.6.6 0 00.08-.68z" />
                      </svg>
                      <span className={tier.highlighted ? "text-cream/70" : "text-text-secondary"}>
                        {feature}
                      </span>
                    </li>
                  ))}
                </ul>
                <Link
                  href="/sign-up"
                  className={`block w-full text-center py-3 rounded-button text-sm font-semibold transition-opacity hover:opacity-90 active:opacity-80 ${
                    tier.highlighted
                      ? "bg-orange text-cream shadow-md shadow-orange/20"
                      : "bg-navy text-cream"
                  }`}
                >
                  {tier.cta}
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ============================================================ */}
      {/*  FINAL CTA                                                   */}
      {/* ============================================================ */}
      <section className="relative py-24 px-6 text-center">
        <div className="absolute inset-0 overflow-hidden pointer-events-none" aria-hidden="true">
          <GeometricCorner className="absolute top-8 left-4 text-gold sm:left-12" />
          <GeometricCorner className="absolute top-8 right-4 text-gold sm:right-12 -scale-x-100" />
        </div>
        <div className="relative z-10 max-w-2xl mx-auto">
          <ArtDecoRule className="text-gold/40 mb-10" />
          <h2 className="!text-3xl sm:!text-4xl !font-bold mb-4">
            Your Strongest Self Starts Here
          </h2>
          <p className="text-text-secondary mb-8 max-w-md mx-auto">
            Join lifters who train smarter — with workouts that respect
            their body, their cycle, and their goals.
          </p>
          <Link
            href="/sign-up"
            className="inline-flex items-center justify-center px-10 py-4 bg-orange text-cream text-base font-semibold rounded-button hover:opacity-90 active:opacity-80 transition-opacity shadow-lg shadow-orange/20"
          >
            Create Your Free Account
          </Link>
        </div>
      </section>

      {/* ============================================================ */}
      {/*  FOOTER                                                      */}
      {/* ============================================================ */}
      <footer className="bg-navy text-cream/40 py-12 px-6">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-6">
            <div>
              <span className="font-heading text-lg font-bold text-cream/80">Sundee Fundee</span>
              <p className="text-xs mt-1">&copy; {new Date().getFullYear()} Sundee Fundee. All rights reserved.</p>
            </div>
            <div className="flex items-center gap-6 text-sm">
              <Link href="/blog" className="hover:text-cream/70 transition-colors">Blog</Link>
              <Link href="/support" className="hover:text-cream/70 transition-colors">Support</Link>
              <Link href="/privacy" className="hover:text-cream/70 transition-colors">Privacy</Link>
              <Link href="/terms" className="hover:text-cream/70 transition-colors">Terms</Link>
            </div>
          </div>
        </div>
      </footer>
    </main>
  );
}
