import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RestTimerPill } from '@/components/rest-timer/RestTimerPill';

// Mock the context hook
const mockContext = {
  status: 'running' as const,
  remainingSeconds: 90,
  durationSeconds: 180,
  exerciseName: 'Back Squat',
  isExpanded: false,
  setExpanded: vi.fn(),
};

vi.mock('@/contexts/RestTimerContext', () => ({
  useRestTimerContext: () => mockContext,
}));

describe('RestTimerPill', () => {
  it('renders when timer is running', () => {
    render(<RestTimerPill />);

    expect(screen.getByText(/1:30/)).toBeInTheDocument();
    expect(screen.getByText(/Back Squat/)).toBeInTheDocument();
  });

  it('does not render when timer is idle', () => {
    mockContext.status = 'idle';
    mockContext.remainingSeconds = 0;

    render(<RestTimerPill />);

    expect(screen.queryByText(/Back Squat/)).not.toBeInTheDocument();
  });

  it('calls setExpanded when clicked', async () => {
    const user = userEvent.setup();
    mockContext.status = 'running';
    mockContext.remainingSeconds = 90;

    render(<RestTimerPill />);

    await user.click(screen.getByRole('button'));

    expect(mockContext.setExpanded).toHaveBeenCalledWith(true);
  });

  it('formats time correctly for minutes and seconds', () => {
    mockContext.remainingSeconds = 125; // 2:05

    render(<RestTimerPill />);

    expect(screen.getByText(/2:05/)).toBeInTheDocument();
  });

  it('shows 0:xx for times under a minute', () => {
    mockContext.remainingSeconds = 45;

    render(<RestTimerPill />);

    expect(screen.getByText(/0:45/)).toBeInTheDocument();
  });
});
