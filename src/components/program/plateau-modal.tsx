'use client';

import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';

interface PlateauEntry {
  exerciseName: string;
  adjustedWeight: number;
}

interface PlateauModalProps {
  isOpen: boolean;
  plateaus: PlateauEntry[];
  onAcknowledge: () => void;
}

export function PlateauModal({ isOpen, plateaus, onAcknowledge }: PlateauModalProps) {
  return (
    <Dialog
      open={isOpen}
      // Prevent dismissal via backdrop click or escape — user must acknowledge
      onOpenChange={() => {}}
    >
      <DialogContent showCloseButton={false}>
        <DialogHeader>
          <DialogTitle>⚠️ Plateau Detected</DialogTitle>
        </DialogHeader>

        <div className="space-y-3">
          {plateaus.map((plateau, index) => (
            <p key={index} className="text-sm">
              You&apos;ve missed prescribed reps on{' '}
              <strong>{plateau.exerciseName}</strong> for 3 sessions in a row.
              Recommendation reduced to{' '}
              <strong>{plateau.adjustedWeight} lbs</strong>.
            </p>
          ))}

          <p className="text-muted-foreground mt-2 text-sm">
            Deloading allows your body to recover and break through plateaus.
          </p>
        </div>

        <DialogFooter>
          <Button className="w-full" onClick={onAcknowledge}>
            Got it, let&apos;s go
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
