'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { CompactListView } from './compact-list-view';
import { SessionCardsView } from './session-cards-view';
import { WeekCalendarView } from './week-calendar-view';
import type { Session } from '@/types/programV2';

export type SessionViewMode = 'session-cards' | 'week-calendar' | 'compact-list';

interface SessionSelectorProps {
  sessions: Session[];
  viewMode: SessionViewMode;
  onSelect: (sessionId: string) => void;
}

export function SessionSelector({ sessions, viewMode, onSelect }: SessionSelectorProps) {
  const [currentView, setCurrentView] = useState<SessionViewMode>(viewMode);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        <Button
          size="sm"
          variant={currentView === 'session-cards' ? 'default' : 'outline'}
          onClick={() => setCurrentView('session-cards')}
        >
          Cards
        </Button>
        <Button
          size="sm"
          variant={currentView === 'week-calendar' ? 'default' : 'outline'}
          onClick={() => setCurrentView('week-calendar')}
        >
          Calendar
        </Button>
        <Button
          size="sm"
          variant={currentView === 'compact-list' ? 'default' : 'outline'}
          onClick={() => setCurrentView('compact-list')}
        >
          List
        </Button>
      </div>

      {currentView === 'session-cards' && (
        <SessionCardsView sessions={sessions} onSelect={onSelect} />
      )}
      {currentView === 'week-calendar' && (
        <WeekCalendarView sessions={sessions} onSelect={onSelect} />
      )}
      {currentView === 'compact-list' && (
        <CompactListView sessions={sessions} onSelect={onSelect} />
      )}
    </div>
  );
}
