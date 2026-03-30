import { Card } from "@/components/ui/card";
import { ArtDecoRule, SectionLabel, SectionHeader } from "@/components/ui/art-deco";
import { ImageWithPlaceholder } from "@/components/install/image-with-placeholder";
import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Install the App — Sundee Fundee",
  description: "Install Sundee Fundee as a Progressive Web App on your iPhone or Android device for offline access and a native app experience.",
  openGraph: {
    title: "Install the App — Sundee Fundee",
    description: "Install Sundee Fundee as a Progressive Web App on your iPhone or Android device for offline access and a native app experience.",
  },
};

export default function InstallPage() {
  return (
    <main className="max-w-[720px] mx-auto">
      <Link href="/support" className="text-gold font-mono text-[11px] tracking-[0.2em] uppercase hover:text-orange transition-colors">
        &larr; Support
      </Link>

      <div className="mt-6 mb-2">
        <SectionLabel className="mb-2">PWA Installation</SectionLabel>
        <h1 className="!text-4xl !font-bold tracking-tight mb-1">Install the App</h1>
        <p className="text-gold font-mono text-[11px] tracking-[0.2em] uppercase">Sundee Fundee</p>
      </div>
      <ArtDecoRule className="text-gold/30 my-6" />

      <p className="mb-8 text-text-secondary leading-relaxed">
        Install Sundee Fundee on your home screen for quick access, offline support, and a
        native app-like experience. No app store required.
      </p>

      {/* Why Install */}
      <Card className="mb-10 border-l-[3px] border-l-gold bg-card-bg/50">
        <h2 className="font-heading font-semibold text-lg mb-3">Why Install the App?</h2>
        <ul className="space-y-2 text-text-secondary text-[14px]">
          <li className="flex items-start gap-2">
            <span className="text-gold mt-0.5">•</span>
            <span><strong className="text-text-primary">Offline access</strong> — View and log workouts without an internet connection</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-gold mt-0.5">•</span>
            <span><strong className="text-text-primary">Home screen icon</strong> — One tap to open, just like a native app</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-gold mt-0.5">•</span>
            <span><strong className="text-text-primary">Full-screen experience</strong> — No browser chrome, more room for your data</span>
          </li>
          <li className="flex items-start gap-2">
            <span className="text-gold mt-0.5">•</span>
            <span><strong className="text-text-primary">Push notifications</strong> — Get workout reminders (coming soon)</span>
          </li>
        </ul>
      </Card>

      {/* iOS Instructions */}
      <section className="mb-12">
        <SectionHeader label="Apple Devices" title="iPhone & iPad" />

        <div className="mt-6 space-y-6">
          <Step number={1} title="Open in Safari">
            <p className="text-text-secondary text-[14px] leading-relaxed">
              Open Safari on your iPhone or iPad and navigate to{" "}
              <strong className="text-text-primary">sundeefundee.com</strong>. The PWA installation
              feature only works in Safari — Chrome and other browsers on iOS don&apos;t support it.
            </p>
            <div className="mt-4 rounded-lg overflow-hidden border border-separator bg-navy/5">
              <ImageWithPlaceholder
                src="/images/install/ios-1.png"
                alt="Screenshot of Safari browser showing sundeefundee.com"
              />
            </div>
          </Step>

          <Step number={2} title="Tap the Share Button">
            <p className="text-text-secondary text-[14px] leading-relaxed">
              Tap the <strong className="text-text-primary">Share button</strong> (the square with
              an arrow pointing up) in the bottom toolbar. It&apos;s located at the bottom of the
              screen on iPhone, or at the top right on iPad.
            </p>
            <div className="mt-4 rounded-lg overflow-hidden border border-separator bg-navy/5">
              <ImageWithPlaceholder
                src="/images/install/ios-2.png"
                alt="Screenshot of iOS share sheet with the share button highlighted"
              />
            </div>
          </Step>

          <Step number={3} title="Tap &quot;Add to Home Screen&quot;">
            <p className="text-text-secondary text-[14px] leading-relaxed">
              Scroll down in the share sheet and tap{" "}
              <strong className="text-text-primary">&quot;Add to Home Screen&quot;</strong>.
              The icon looks like a square with a plus sign. If you don&apos;t see it, scroll to
              the right and tap &quot;More&quot; to find it.
            </p>
            <div className="mt-4 rounded-lg overflow-hidden border border-separator bg-navy/5">
              <ImageWithPlaceholder
                src="/images/install/ios-3.png"
                alt="Screenshot of iOS share sheet showing Add to Home Screen option"
              />
            </div>
          </Step>

          <Step number={4} title="Name It and Tap &quot;Add&quot;">
            <p className="text-text-secondary text-[14px] leading-relaxed">
              You&apos;ll see a preview of the app icon. You can keep the default name or change it.
              Tap <strong className="text-text-primary">&quot;Add&quot;</strong> in the top right
              corner. The app will now appear on your home screen!
            </p>
            <div className="mt-4 rounded-lg overflow-hidden border border-separator bg-navy/5">
              <ImageWithPlaceholder
                src="/images/install/ios-4.png"
                alt="Screenshot of iOS Add to Home Screen preview dialog"
              />
            </div>
          </Step>
        </div>
      </section>

      {/* Android Instructions */}
      <section className="mb-12">
        <SectionHeader label="Android Devices" title="Phones & Tablets" />

        <div className="mt-6 space-y-6">
          <Step number={1} title="Open in Chrome">
            <p className="text-text-secondary text-[14px] leading-relaxed">
              Open Google Chrome on your Android device and navigate to{" "}
              <strong className="text-text-primary">sundeefundee.com</strong>. Chrome provides the
              best PWA experience on Android.
            </p>
            <div className="mt-4 rounded-lg overflow-hidden border border-separator bg-navy/5">
              <ImageWithPlaceholder
                src="/images/install/android-1.png"
                alt="Screenshot of Chrome browser on Android showing sundeefundee.com"
              />
            </div>
          </Step>

          <Step number={2} title="Tap the Menu (⋮)">
            <p className="text-text-secondary text-[14px] leading-relaxed">
              Tap the <strong className="text-text-primary">three-dot menu</strong> (⋮) in the top
              right corner of Chrome. Alternatively, you may see an &quot;Install&quot; banner at
              the bottom of the screen — tap that to skip ahead.
            </p>
            <div className="mt-4 rounded-lg overflow-hidden border border-separator bg-navy/5">
              <ImageWithPlaceholder
                src="/images/install/android-2.png"
                alt="Screenshot of Chrome menu on Android with the three-dot menu highlighted"
              />
            </div>
          </Step>

          <Step number={3} title="Tap &quot;Install app&quot; or &quot;Add to Home Screen&quot;">
            <p className="text-text-secondary text-[14px] leading-relaxed">
              In the menu, look for <strong className="text-text-primary">&quot;Install app&quot;</strong>{" "}
              or <strong className="text-text-primary">&quot;Add to Home Screen&quot;</strong>.
              The wording varies by Android version. If you see &quot;Install&quot; in a bottom banner,
              you can tap that instead.
            </p>
            <div className="mt-4 rounded-lg overflow-hidden border border-separator bg-navy/5">
              <ImageWithPlaceholder
                src="/images/install/android-3.png"
                alt="Screenshot of Chrome menu showing Install app option"
              />
            </div>
          </Step>

          <Step number={4} title="Confirm Installation">
            <p className="text-text-secondary text-[14px] leading-relaxed">
              A dialog will appear confirming the installation. Tap{" "}
              <strong className="text-text-primary">&quot;Install&quot;</strong>. The app will be
              added to your home screen and app drawer!
            </p>
            <div className="mt-4 rounded-lg overflow-hidden border border-separator bg-navy/5">
              <ImageWithPlaceholder
                src="/images/install/android-4.png"
                alt="Screenshot of Android install confirmation dialog"
              />
            </div>
          </Step>
        </div>
      </section>

      {/* Troubleshooting */}
      <section className="mb-12">
        <SectionHeader label="Having Issues?" title="Troubleshooting" />

        <div className="flex flex-col gap-4 mt-4">
          <Faq question="I don&apos;t see &quot;Add to Home Screen&quot; on my iPhone">
            Make sure you&apos;re using <strong>Safari</strong> — not Chrome, Firefox, or another
            browser. Apple only allows PWA installation from Safari. Also check that you&apos;re on
            iOS 11.3 or later.
          </Faq>

          <Faq question="The app icon didn&apos;t appear on my home screen">
            Check all your home screen pages — it may have been added to a page with space.
            On iPhone, swipe left to the App Library and search for &quot;Sundee Fundee&quot;.
            On Android, check your app drawer.
          </Faq>

          <Faq question="The app asks me to sign in again">
            Your session is stored locally. If you clear your browser data or site data,
            you&apos;ll need to sign in again. To avoid this, don&apos;t clear site data for
            sundeefundee.com.
          </Faq>

          <Faq question="Can I move the app to a different location?">
            Yes! On both iPhone and Android, you can long-press the app icon and drag it to
            any position on your home screen, just like any other app.
          </Faq>

          <Faq question="How do I uninstall the PWA?">
            On iPhone: Long-press the app icon, tap &quot;Remove App&quot;, then &quot;Delete App&quot;.
            On Android: Long-press the app icon and drag it to &quot;Uninstall&quot; or &quot;Remove&quot;.
            This won&apos;t delete your account — your data is safe in the cloud.
          </Faq>
        </div>
      </section>

      {/* Back to Support */}
      <div className="pt-6 border-t border-separator">
        <Link
          href="/support"
          className="text-gold font-mono text-[11px] tracking-[0.2em] uppercase hover:text-orange transition-colors"
        >
          &larr; Back to Support
        </Link>
      </div>
    </main>
  );
}

/* ------------------------------------------------------------------ */
/*  Step component                                                    */
/* ------------------------------------------------------------------ */

function Step({ number, title, children }: { number: number; title: string; children: React.ReactNode }) {
  return (
    <div className="flex gap-4">
      <div className="flex-shrink-0 w-8 h-8 rounded-full bg-gold/10 border border-gold/30 flex items-center justify-center">
        <span className="font-mono text-sm font-bold text-gold">{number}</span>
      </div>
      <div className="flex-1 -mt-1">
        <h3 className="font-heading font-semibold text-base mb-2">{title}</h3>
        {children}
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/*  FAQ component                                                     */
/* ------------------------------------------------------------------ */

function Faq({ question, children }: { question: string; children: React.ReactNode }) {
  return (
    <Card className="hover:shadow-md transition-shadow">
      <p className="font-heading font-semibold mb-2">{question}</p>
      <p className="text-text-secondary text-[14px] leading-relaxed">{children}</p>
    </Card>
  );
}
