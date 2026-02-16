import { describe, it, expect } from 'vitest';
import { TRANSITION_DEFAULTS, VARIANTS } from '@/lib/animations';

describe('Animation Config', () => {
  it('has default transition settings', () => {
    expect(TRANSITION_DEFAULTS.duration).toBe(0.3);
    expect(Array.isArray(TRANSITION_DEFAULTS.ease)).toBe(true);
  });

  it('defines fade in variants', () => {
    expect(VARIANTS.fadeIn.initial.opacity).toBe(0);
    expect(VARIANTS.fadeIn.animate.opacity).toBe(1);
  });

  it('defines scale press variants', () => {
    expect(VARIANTS.scalePress.tap.scale).toBeLessThan(1);
  });
});
