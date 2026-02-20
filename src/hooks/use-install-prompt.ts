'use client';

import { useEffect, useState } from 'react';

interface BeforeInstallPromptEvent extends Event {
  readonly platforms: string[];
  readonly userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
  prompt(): Promise<void>;
}

const ANDROID_DISMISS_KEY = 'pwa-install-dismissed';
const IOS_DISMISS_KEY = 'ios-install-dismissed';

export function useInstallPrompt() {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null);

  useEffect(() => {
    // Skip if user already dismissed the prompt
    if (localStorage.getItem(ANDROID_DISMISS_KEY)) return;

    // Skip if already running as installed PWA (standalone mode)
    if (window.matchMedia('(display-mode: standalone)').matches) return;

    const handler = (e: Event) => {
      e.preventDefault(); // Prevent Chrome mini-infobar
      setDeferredPrompt(e as BeforeInstallPromptEvent);
    };

    window.addEventListener('beforeinstallprompt', handler);
    return () => window.removeEventListener('beforeinstallprompt', handler);
  }, []);

  async function promptInstall() {
    if (!deferredPrompt) return;
    await deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === 'dismissed') {
      localStorage.setItem(ANDROID_DISMISS_KEY, '1');
    }
    setDeferredPrompt(null);
  }

  function dismiss() {
    localStorage.setItem(ANDROID_DISMISS_KEY, '1');
    setDeferredPrompt(null);
  }

  return { canInstall: !!deferredPrompt, promptInstall, dismiss };
}

export function useIsIosInstallable() {
  const [show, setShow] = useState(false);

  useEffect(() => {
    const isIos = /iPhone|iPad|iPod/i.test(navigator.userAgent);
    const isStandalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      ('standalone' in navigator && (navigator as { standalone?: boolean }).standalone === true);
    const isDismissed = !!localStorage.getItem(IOS_DISMISS_KEY);
    setShow(isIos && !isStandalone && !isDismissed);
  }, []);

  function dismiss() {
    localStorage.setItem(IOS_DISMISS_KEY, '1');
    setShow(false);
  }

  return { showIosPrompt: show, dismissIos: dismiss };
}
