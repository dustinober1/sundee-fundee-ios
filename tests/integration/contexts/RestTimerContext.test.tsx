import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, act } from '@testing-library/react';
import { ReactNode } from 'react';
import {
  RestTimerProvider,
  useRestTimerContext,
} from '@/contexts/RestTimerContext';

function TestComponent() {
  const {
    status,
    remainingSeconds,
    exerciseName,
    startRest,
    pause,
    resume,
    cancel,
  } = useRestTimerContext();

  return (
    <div>
      <span data-testid="status">{status}</span>
      <span data-testid="remaining">{remainingSeconds}</span>
      <span data-testid="exercise">{exerciseName}</span>
      <button onClick={() => startRest(60, 'Test Exercise')}>Start</button>
      <button onClick={pause}>Pause</button>
      <button onClick={resume}>Resume</button>
      <button onClick={cancel}>Cancel</button>
    </div>
  );
}

function renderWithProvider(ui: ReactNode) {
  return render(<RestTimerProvider>{ui}</RestTimerProvider>);
}

describe('RestTimerContext', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('provides timer state to children', () => {
    renderWithProvider(<TestComponent />);

    expect(screen.getByTestId('status').textContent).toBe('idle');
    expect(screen.getByTestId('remaining').textContent).toBe('0');
  });

  it('allows starting rest timer', () => {
    renderWithProvider(<TestComponent />);

    act(() => {
      screen.getByText('Start').click();
    });

    expect(screen.getByTestId('status').textContent).toBe('running');
    expect(screen.getByTestId('remaining').textContent).toBe('60');
    expect(screen.getByTestId('exercise').textContent).toBe('Test Exercise');
  });

  it('allows pausing and resuming', async () => {
    renderWithProvider(<TestComponent />);

    act(() => {
      screen.getByText('Start').click();
    });

    await act(async () => {
      await vi.advanceTimersByTimeAsync(10000);
    });

    act(() => {
      screen.getByText('Pause').click();
    });
    expect(screen.getByTestId('status').textContent).toBe('paused');

    act(() => {
      screen.getByText('Resume').click();
    });
    expect(screen.getByTestId('status').textContent).toBe('running');
  });

  it('allows canceling timer', () => {
    renderWithProvider(<TestComponent />);

    act(() => {
      screen.getByText('Start').click();
    });

    act(() => {
      screen.getByText('Cancel').click();
    });

    expect(screen.getByTestId('status').textContent).toBe('idle');
    expect(screen.getByTestId('remaining').textContent).toBe('0');
    expect(screen.getByTestId('exercise').textContent).toBe('');
  });
});
