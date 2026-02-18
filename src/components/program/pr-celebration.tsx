'use client';

import { useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useConfetti } from '@/hooks/use-confetti';

interface PRCelebrationProps {
  isVisible: boolean;
  prType: 'weight' | 'volume' | null;
  onDismiss: () => void;
}

export function PRCelebration({ isVisible, prType, onDismiss }: PRCelebrationProps) {
  const { firePRConfetti } = useConfetti();

  useEffect(() => {
    if (!isVisible) return;

    // Fire dense confetti burst for PR
    firePRConfetti();

    // Haptic feedback (mobile)
    if (typeof navigator !== 'undefined' && navigator.vibrate) {
      navigator.vibrate([100, 50, 100, 50, 300]);
    }

    // Dispatch custom event for sound effect
    window.dispatchEvent(new CustomEvent('pr-achieved'));

    // Auto-dismiss after 3.5 seconds
    const timer = setTimeout(() => {
      onDismiss();
    }, 3500);

    return () => clearTimeout(timer);
  }, [isVisible, firePRConfetti, onDismiss]);

  // Listen for pr-achieved event to play sound
  useEffect(() => {
    function handlePRSound() {
      try {
        const audio = new Audio('/sounds/pr.mp3');
        audio.play().catch(() => {
          // Sound is additive, not critical — silently ignore errors
        });
      } catch {
        // Silently ignore — sound file may not exist
      }
    }

    window.addEventListener('pr-achieved', handlePRSound);
    return () => window.removeEventListener('pr-achieved', handlePRSound);
  }, []);

  const subtitle =
    prType === 'weight' ? 'New Weight Record!' : 'New Volume Record!';

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          className="fixed inset-0 z-[200] flex cursor-pointer flex-col items-center justify-center bg-black/60"
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.95 }}
          transition={{ duration: 0.25 }}
          onClick={onDismiss}
        >
          <motion.div
            className="flex flex-col items-center gap-4 text-center"
            initial={{ y: 20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: -20, opacity: 0 }}
            transition={{ delay: 0.05, duration: 0.3 }}
          >
            <span className="text-8xl">🏆</span>
            <h2 className="text-5xl font-bold text-white">New PR!</h2>
            <p className="text-2xl font-semibold text-yellow-300">{subtitle}</p>
            <p className="mt-4 text-sm text-white/70">Tap to continue</p>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
