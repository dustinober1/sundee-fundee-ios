import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { FadeIn, ScaleButton, StaggerList, StaggerItem } from '@/components/animations';

describe('Animation Components', () => {
  it('renders FadeIn content', () => {
    render(<FadeIn>Test Content</FadeIn>);
    expect(screen.getByText('Test Content')).toBeInTheDocument();
  });

  it('renders ScaleButton content', () => {
    render(<ScaleButton>Click Me</ScaleButton>);
    expect(screen.getByText('Click Me')).toBeInTheDocument();
  });

  it('renders StaggerList content', () => {
    render(
      <StaggerList>
        <StaggerItem>Item 1</StaggerItem>
        <StaggerItem>Item 2</StaggerItem>
      </StaggerList>
    );
    expect(screen.getByText('Item 1')).toBeInTheDocument();
    expect(screen.getByText('Item 2')).toBeInTheDocument();
  });
});
