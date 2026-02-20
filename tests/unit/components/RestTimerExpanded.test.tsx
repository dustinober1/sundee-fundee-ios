import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RestTimerExpanded } from '@/components/rest-timer/RestTimerExpanded';
import type { TimerStatus } from '@/types/rest-timer';

const mockContext = {
  status: 'running' as TimerStatus,
  remainingSeconds: 90,
  durationSeconds: 180,
  exerciseName: 'Back Squat',
  isExpanded: true,
  pause: vi.fn(),
  resume: vi.fn(),
  addTime: vi.fn(),
  subtractTime: vi.fn(),
  cancel: vi.fn(),
  skip: vi.fn(),
  setExpanded: vi.fn(),
};

vi.mock('@/contexts/RestTimerContext', () => ({
  useRestTimerContext: () => mockContext,
}));

describe('RestTimerExpanded', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockContext.isExpanded = true;
    mockContext.status = 'running';
  });

  it('renders when expanded', () => {
    render(<RestTimerExpanded />);

    expect(screen.getByText(/1:30/)).toBeInTheDocument();
    expect(screen.getByText(/Back Squat/)).toBeInTheDocument();
  });

  it('does not render when not expanded', () => {
    mockContext.isExpanded = false;

    render(<RestTimerExpanded />);

    expect(screen.queryByText(/Back Squat/)).not.toBeInTheDocument();
  });

  it('shows pause button when running', () => {
    mockContext.isExpanded = true;
    mockContext.status = 'running';

    render(<RestTimerExpanded />);

    expect(screen.getByRole('button', { name: /pause/i })).toBeInTheDocument();
  });

  it('shows resume button when paused', () => {
    mockContext.status = 'paused';

    render(<RestTimerExpanded />);

    expect(screen.getByRole('button', { name: /resume/i })).toBeInTheDocument();
  });

  it('calls addTime when +30s button clicked', async () => {
    const user = userEvent.setup();
    mockContext.status = 'running';

    render(<RestTimerExpanded />);

    await user.click(screen.getByRole('button', { name: /\+30s/i }));

    expect(mockContext.addTime).toHaveBeenCalledWith(30);
  });

  it('calls subtractTime when -30s button clicked', async () => {
    const user = userEvent.setup();

    render(<RestTimerExpanded />);

    await user.click(screen.getByRole('button', { name: /-30s/i }));

    expect(mockContext.subtractTime).toHaveBeenCalledWith(30);
  });

  it('calls skip when skip button clicked', async () => {
    const user = userEvent.setup();

    render(<RestTimerExpanded />);

    await user.click(screen.getByRole('button', { name: /skip/i }));

    expect(mockContext.skip).toHaveBeenCalled();
  });

  it('calls cancel and closes when cancel button clicked', async () => {
    const user = userEvent.setup();

    render(<RestTimerExpanded />);

    await user.click(screen.getByRole('button', { name: /cancel/i }));

    expect(mockContext.cancel).toHaveBeenCalled();
    expect(mockContext.setExpanded).toHaveBeenCalledWith(false);
  });
});
