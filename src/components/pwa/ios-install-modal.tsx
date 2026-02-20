'use client';

import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Share, PlusSquare } from 'lucide-react';

interface IosInstallModalProps {
  open: boolean;
  onDismiss: () => void;
}

export function IosInstallModal({ open, onDismiss }: IosInstallModalProps) {
  function handleDismiss() {
    onDismiss();
  }

  return (
    <Dialog open={open} onOpenChange={(v) => !v && handleDismiss()}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Add to Home Screen</DialogTitle>
        </DialogHeader>
        <ol className="space-y-3 text-sm">
          <li className="flex items-center gap-2">
            <Share className="h-5 w-5 text-primary shrink-0" />
            Tap the <strong>Share</strong> button in Safari&apos;s toolbar
          </li>
          <li className="flex items-center gap-2">
            <PlusSquare className="h-5 w-5 text-primary shrink-0" />
            Scroll down and tap <strong>&quot;Add to Home Screen&quot;</strong>
          </li>
        </ol>
        <Button className="w-full mt-2" onClick={handleDismiss}>
          Got it
        </Button>
      </DialogContent>
    </Dialog>
  );
}
