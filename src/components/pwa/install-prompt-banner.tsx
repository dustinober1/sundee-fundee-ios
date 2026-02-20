'use client';

import { useInstallPrompt } from '@/hooks/use-install-prompt';
import { Button } from '@/components/ui/button';
import { Download, X } from 'lucide-react';

export function InstallPromptBanner() {
  const { canInstall, promptInstall, dismiss } = useInstallPrompt();

  if (!canInstall) return null;

  return (
    <div className="flex items-center justify-between gap-2 rounded-md border border-primary/30 bg-primary/5 px-3 py-2 text-sm mb-4">
      <div className="flex items-center gap-2">
        <Download className="h-4 w-4 text-primary shrink-0" />
        <span>Install Sundee-Fundee for the best experience</span>
      </div>
      <div className="flex items-center gap-1">
        <Button size="sm" variant="default" onClick={promptInstall}>
          Install
        </Button>
        <Button size="sm" variant="ghost" onClick={dismiss} aria-label="Dismiss">
          <X className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}
