'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import type { Session } from '@/types/programV2';

interface SessionCardsViewProps {
  sessions: Session[];
  onSelect: (sessionId: string) => void;
}

export function SessionCardsView({ sessions, onSelect }: SessionCardsViewProps) {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      {sessions.map(session => (
        <Card
          key={session.sessionId}
          className="cursor-pointer transition-shadow hover:shadow-md"
          onClick={() => onSelect(session.sessionId)}
        >
          <CardHeader>
            <CardTitle className="text-lg">{session.sessionName}</CardTitle>
            <CardDescription>{session.focus}</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground text-sm">
              {session.exercises.length} exercise{session.exercises.length !== 1 ? 's' : ''}
            </p>
          </CardContent>
        </Card>
      ))}
    </div>
  );
}
