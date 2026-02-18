import confetti from 'canvas-confetti';
import { useCallback } from 'react';

export function useConfetti() {
  const fireConfetti = useCallback(() => {
    const duration = 3000;
    const end = Date.now() + duration;

    // Launch confetti from bottom center
    confetti({
      particleCount: 100,
      spread: 70,
      origin: { y: 0.8 },
      colors: ['#26ccff', '#a25afd', '#ff5e7e', '#88ff5a', '#fcff42', '#ffa62d', '#ff36ff']
    });

    // Add a few random bursts
    const interval: ReturnType<typeof setInterval> = setInterval(function() {
      if (Date.now() > end) {
        return clearInterval(interval);
      }

      confetti({
        startVelocity: 30,
        spread: 360,
        ticks: 60,
        origin: {
          x: Math.random() * (0.7 - 0.3) + 0.3,
          y: Math.random() - 0.2
        },
        colors: ['#26ccff', '#a25afd', '#ff5e7e', '#88ff5a', '#fcff42', '#ffa62d', '#ff36ff']
      });
    }, 250);
  }, []);

  /**
   * Dense full-screen confetti burst for PR celebrations.
   * Fires an initial burst from both sides, then sustained bursts across the full screen.
   */
  const firePRConfetti = useCallback(() => {
    const duration = 4000;
    const end = Date.now() + duration;

    // Initial burst from both sides (full-screen takeover)
    confetti({ particleCount: 150, spread: 100, origin: { x: 0.25, y: 0.6 }, zIndex: 9999 });
    confetti({ particleCount: 150, spread: 100, origin: { x: 0.75, y: 0.6 }, zIndex: 9999 });

    // Sustained bursts across screen
    const interval: ReturnType<typeof setInterval> = setInterval(() => {
      if (Date.now() > end) {
        clearInterval(interval);
        return;
      }
      confetti({
        startVelocity: 20,
        spread: 360,
        ticks: 80,
        zIndex: 9999,
        origin: { x: Math.random(), y: Math.random() * 0.4 },
        colors: ['#26ccff', '#a25afd', '#ff5e7e', '#88ff5a', '#fcff42', '#ffa62d'],
      });
    }, 200);
  }, []);

  return { fireConfetti, firePRConfetti };
}
