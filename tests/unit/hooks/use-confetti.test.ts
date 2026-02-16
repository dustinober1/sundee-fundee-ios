import { describe, it, expect, vi } from 'vitest';
import { renderHook } from '@testing-library/react';
import { useConfetti } from '@/hooks/use-confetti';

// Mock canvas-confetti
vi.mock('canvas-confetti', () => ({
  default: vi.fn(),
}));

describe('useConfetti', () => {
  it('returns fireConfetti function', () => {
    const { result } = renderHook(() => useConfetti());
    expect(typeof result.current.fireConfetti).toBe('function');
  });
});
