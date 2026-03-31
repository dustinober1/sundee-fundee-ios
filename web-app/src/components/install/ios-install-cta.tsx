"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";

const DISMISS_KEY = "sf-ios-install-dismissed";

type IOSInstallCtaProps = {
  className?: string;
  persistent?: boolean;
};

type InstallState = {
  ready: boolean;
  isIOS: boolean;
  isSafari: boolean;
  isStandalone: boolean;
  dismissed: boolean;
};

const initialState: InstallState = {
  ready: false,
  isIOS: false,
  isSafari: false,
  isStandalone: false,
  dismissed: false,
};

function getInstallSnapshot(persistent: boolean): InstallState {
  if (typeof window === "undefined") {
    return initialState;
  }

  const userAgent = window.navigator.userAgent;
  const platform = window.navigator.platform;
  const isIOSDevice =
    /iPad|iPhone|iPod/.test(userAgent) ||
    (platform === "MacIntel" && window.navigator.maxTouchPoints > 1);
  const isSafariBrowser =
    /Safari/i.test(userAgent) && !/CriOS|FxiOS|EdgiOS|OPiOS|DuckDuckGo/i.test(userAgent);
  const isStandaloneDisplay =
    window.matchMedia("(display-mode: standalone)").matches ||
    ((window.navigator as Navigator & { standalone?: boolean }).standalone === true);
  const dismissed = persistent ? false : window.localStorage.getItem(DISMISS_KEY) === "1";

  return {
    ready: true,
    isIOS: isIOSDevice,
    isSafari: isSafariBrowser,
    isStandalone: isStandaloneDisplay,
    dismissed,
  };
}

export function IOSInstallCta({
  className = "",
  persistent = false,
}: IOSInstallCtaProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [installState, setInstallState] = useState<InstallState>(initialState);

  useEffect(() => {
    const frame = window.requestAnimationFrame(() => {
      setInstallState(getInstallSnapshot(persistent));
    });

    return () => window.cancelAnimationFrame(frame);
  }, [persistent]);

  if (!installState.ready || !installState.isIOS || installState.isStandalone) {
    return null;
  }

  if (installState.dismissed && !persistent) {
    return null;
  }

  const title = installState.isSafari ? "Install on iPhone" : "Open in Safari to Install";
  const description = installState.isSafari
    ? "Add Sundee Fundee to your home screen for a clean, app-like launch."
    : "iPhone installation only works in Safari. Open this page there, then use Add to Home Screen.";

  const dismiss = () => {
    if (!persistent) {
      window.localStorage.setItem(DISMISS_KEY, "1");
      setInstallState((current) => ({ ...current, dismissed: true }));
    }
    setIsOpen(false);
  };

  return (
    <>
      <Card className={`border border-gold/30 bg-card-bg/95 shadow-lg shadow-navy/5 ${className}`}>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div className="max-w-md">
            <p className="font-mono text-[11px] uppercase tracking-[0.24em] text-gold">
              iPhone Install
            </p>
            <h2 className="mt-1 font-heading text-xl font-semibold text-navy">{title}</h2>
            <p className="mt-2 text-sm leading-relaxed text-text-secondary">{description}</p>
          </div>

          <div className="flex flex-col gap-2 sm:min-w-[220px]">
            <Button className="font-semibold" onClick={() => setIsOpen(true)} type="button">
              {installState.isSafari ? "Install Sundee Fundee" : "See iPhone Steps"}
            </Button>
            {!persistent ? (
              <button
                type="button"
                className="text-xs font-medium text-text-secondary transition-opacity hover:opacity-70"
                onClick={dismiss}
              >
                Hide for now
              </button>
            ) : null}
          </div>
        </div>
      </Card>

      {isOpen ? (
        <div
          className="fixed inset-0 z-[70] flex items-end justify-center bg-navy/45 px-4 py-6 backdrop-blur-sm sm:items-center"
          role="dialog"
          aria-modal="true"
          aria-labelledby="ios-install-title"
        >
          <div className="w-full max-w-lg rounded-[28px] border border-gold/20 bg-cream shadow-2xl shadow-navy/20">
            <div className="flex items-start justify-between gap-4 border-b border-separator px-6 py-5">
              <div>
                <p className="font-mono text-[11px] uppercase tracking-[0.24em] text-gold">
                  Install Sundee Fundee
                </p>
                <h3 id="ios-install-title" className="mt-1 font-heading text-2xl font-semibold">
                  {installState.isSafari ? "Almost there" : "Open Safari first"}
                </h3>
              </div>
              <button
                type="button"
                className="rounded-full border border-separator p-2 text-text-secondary transition-colors hover:border-navy/20 hover:text-navy"
                onClick={() => setIsOpen(false)}
                aria-label="Close install instructions"
              >
                <CloseIcon />
              </button>
            </div>

            <div className="space-y-4 px-6 py-5">
              {installState.isSafari ? (
                <>
                  <InstallStep
                    number="1"
                    icon={<ShareIcon />}
                    title="Tap the Share button"
                    description="Use Safari’s square-and-arrow button at the bottom of the screen."
                  />
                  <InstallStep
                    number="2"
                    icon={<AddIcon />}
                    title="Tap Add to Home Screen"
                    description="Scroll if needed, then confirm with Add in the top-right corner."
                  />
                </>
              ) : (
                <>
                  <InstallStep
                    number="1"
                    icon={<CompassIcon />}
                    title="Open this page in Safari"
                    description="Tap the browser menu and choose to open or paste this URL in Safari."
                  />
                  <InstallStep
                    number="2"
                    icon={<ShareIcon />}
                    title="Tap Share, then Add to Home Screen"
                    description="Safari is the only iPhone browser that can install the app."
                  />
                </>
              )}

              <div className="rounded-2xl border border-gold/20 bg-gold/8 px-4 py-3 text-sm text-text-secondary">
                Once installed, Sundee Fundee launches full-screen from your home screen like a native app.
              </div>
            </div>

            <div className="flex flex-col gap-3 border-t border-separator px-6 py-5 sm:flex-row sm:justify-end">
              <Link
                href="/support/install"
                className="inline-flex items-center justify-center rounded-button border border-navy/15 px-5 py-3 text-sm font-medium text-navy transition-colors hover:bg-separator/30"
              >
                Full install guide
              </Link>
              <Button className="px-5 py-3 text-sm font-semibold" onClick={() => setIsOpen(false)} type="button">
                Got it
              </Button>
            </div>
          </div>
        </div>
      ) : null}
    </>
  );
}

function InstallStep({
  number,
  icon,
  title,
  description,
}: {
  number: string;
  icon: React.ReactNode;
  title: string;
  description: string;
}) {
  return (
    <div className="flex gap-4 rounded-2xl border border-separator bg-card-bg/70 p-4">
      <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full border border-gold/30 bg-gold/10 font-mono text-sm font-bold text-gold">
        {number}
      </div>
      <div className="flex flex-1 items-start gap-3">
        <div className="mt-0.5 flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-2xl bg-navy text-cream">
          {icon}
        </div>
        <div>
          <p className="font-heading text-base font-semibold text-navy">{title}</p>
          <p className="mt-1 text-sm leading-relaxed text-text-secondary">{description}</p>
        </div>
      </div>
    </div>
  );
}

function CloseIcon() {
  return (
    <svg viewBox="0 0 16 16" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.5">
      <path d="M4 4L12 12" />
      <path d="M12 4L4 12" />
    </svg>
  );
}

function ShareIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.7">
      <path d="M12 16V4" />
      <path d="M8 8l4-4 4 4" />
      <path d="M5 11v7a1 1 0 001 1h12a1 1 0 001-1v-7" />
    </svg>
  );
}

function AddIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.7">
      <rect x="4" y="4" width="16" height="16" rx="3" />
      <path d="M12 8v8" />
      <path d="M8 12h8" />
    </svg>
  );
}

function CompassIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.7">
      <circle cx="12" cy="12" r="8" />
      <path d="M14.8 9.2l-2.2 5.6-5.4 2.2 2.2-5.6 5.4-2.2z" />
    </svg>
  );
}
