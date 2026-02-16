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
    const interval: any = setInterval(function() {
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

  return { fireConfetti };
}
