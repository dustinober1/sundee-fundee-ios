'use client';

import { Card, CardContent } from '@/components/ui/card';
import type { Session } from '@/types/programV2';

interface WeekCalendarViewProps {
  sessions: Session[];
  onSelect: (sessionId: string) => void;
}

export function WeekCalendarView({ sessions, onSelect }: WeekCalendarViewProps) {
  return (
    <div className="grid grid-cols-1 gap-3 sm:grid-cols-3">
      {sessions.map(session => (
        <Card
          key={session.sessionId}
          className="cursor-pointer transition-shadow hover:shadow-md"
          onClick={() => onSelect(session.sessionId)}
        >
          <CardContent className="space-y-1 p-4 text-center">
            <p className="text-sm font-semibold">{session.sessionName}</p>
            <p className="text-muted-foreground text-xs">{session.focus}</p>
            <p className="text-muted-foreground text-xs">
              {session.exercises.length} exercise{session.exercises.length !== 1 ? 's' : ''}
            </p>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
