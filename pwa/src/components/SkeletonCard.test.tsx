import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { SkeletonCard } from './SkeletonCard';

describe('SkeletonCard', () => {
  it('renders 4 shimmer elements by default', () => {
    const { container } = render(<SkeletonCard />);
    const cards = container.querySelectorAll('[aria-hidden="true"]');
    expect(cards.length).toBe(4);
  });

  it('renders exactly 2 shimmer elements when count=2', () => {
    const { container } = render(<SkeletonCard count={2} />);
    const cards = container.querySelectorAll('[aria-hidden="true"]');
    expect(cards.length).toBe(2);
  });

  it('renders exactly 6 shimmer elements when count=6', () => {
    const { container } = render(<SkeletonCard count={6} />);
    const cards = container.querySelectorAll('[aria-hidden="true"]');
    expect(cards.length).toBe(6);
  });

  it('each shimmer element has a class applied for card styling', () => {
    const { container } = render(<SkeletonCard count={1} />);
    const card = container.querySelector('[aria-hidden="true"]');
    expect(card).not.toBeNull();
    expect(card!.className).toBeTruthy();
  });

  it('applies custom height via style prop', () => {
    const { container } = render(<SkeletonCard count={1} height={120} />);
    const card = container.querySelector('[aria-hidden="true"]') as HTMLElement;
    expect(card.style.height).toBe('120px');
  });
});
