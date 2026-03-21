/**
 * useInstallPrompt — cross-platform PWA install prompt hook.
 * - Android: captures `beforeinstallprompt` event for native install flow
 * - iOS Safari: detects via user agent and shows instruction banner
 * - Standalone: suppresses all prompts when already installed
 * - Session-scoped dismissal via sessionStorage
 */
import { useCallback, useEffect, useState } from 'react';

export interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed'; platform: string }>;
}

export interface UseInstallPromptResult {
  androidPrompt: BeforeInstallPromptEvent | null;
  isIOS: boolean;
  isStandalone: boolean;
  isDismissed: boolean;
  showPrompt: boolean;
  triggerAndroid: () => Promise<void>;
  dismiss: () => void;
}

export function useInstallPrompt(): UseInstallPromptResult {
  const [androidPrompt, setAndroidPrompt] = useState<BeforeInstallPromptEvent | null>(null);

  const isStandalone =
    window.matchMedia('(display-mode: standalone)').matches ||
    (navigator as unknown as { standalone?: boolean }).standalone === true;

  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !isStandalone;

  const [isDismissed, setIsDismissed] = useState(
    () => window.sessionStorage.getItem('installPromptDismissed') === '1'
  );

  useEffect(() => {
    if (isStandalone) return;

    function handleBeforeInstallPrompt(e: Event) {
      e.preventDefault();
      setAndroidPrompt(e as BeforeInstallPromptEvent);
    }

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, [isStandalone]);

  const dismiss = useCallback(() => {
    window.sessionStorage.setItem('installPromptDismissed', '1');
    setIsDismissed(true);
  }, []);

  const triggerAndroid = useCallback(async () => {
    if (!androidPrompt) return;
    await androidPrompt.prompt();
    const choice = await androidPrompt.userChoice;
    if (choice.outcome === 'dismissed') {
      dismiss();
    }
    setAndroidPrompt(null);
  }, [androidPrompt, dismiss]);

  const showPrompt = (androidPrompt !== null || isIOS) && !isDismissed && !isStandalone;

  return {
    androidPrompt,
    isIOS,
    isStandalone,
    isDismissed,
    showPrompt,
    triggerAndroid,
    dismiss,
  };
}
