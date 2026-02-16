import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { SessionSelector } from '@/components/program/session-selector';
import type { Session } from '@/types/programV2';

const mockSessions: Session[] = [
  {
    sessionId: 'w1-a',
    sessionName: 'Support Session A',
    sessionType: 'support',
    focus: 'Positional Strength',
    exercises: [],
  },
  {
    sessionId: 'w1-b',
    sessionName: 'Support Session B',
    sessionType: 'support',
    focus: 'Structural Balance',
    exercises: [],
  },
  {
    sessionId: 'w1-sunday',
    sessionName: 'Sunday Anchor',
    sessionType: 'anchor',
    focus: 'Heavy Main Lift',
    exercises: [],
  }
];

describe('SessionSelector', () => {
  it('displays all sessions in cards view', () => {
    const onSelect = vi.fn();

    render(
      <SessionSelector
        sessions={mockSessions}
        viewMode="session-cards"
        onSelect={onSelect}
      />
    );

    expect(screen.getByText('Support Session A')).toBeInTheDocument();
    expect(screen.getByText('Support Session B')).toBeInTheDocument();
    expect(screen.getByText('Sunday Anchor')).toBeInTheDocument();
  });

  it('calls onSelect when session is clicked', async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();

    render(
      <SessionSelector
        sessions={mockSessions}
        viewMode="session-cards"
        onSelect={onSelect}
      />
    );

    await user.click(screen.getByText('Support Session A'));
    expect(onSelect).toHaveBeenCalledWith('w1-a');
  });

  it('shows session focus in cards view', () => {
    render(
      <SessionSelector
        sessions={mockSessions}
        viewMode="session-cards"
        onSelect={() => {}}
      />
    );

    expect(screen.getByText('Positional Strength')).toBeInTheDocument();
  });
});
