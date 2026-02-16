'use client';

import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import type { Session } from '@/types/programV2';

interface CompactListViewProps {
  sessions: Session[];
  onSelect: (sessionId: string) => void;
}

export function CompactListView({ sessions, onSelect }: CompactListViewProps) {
  return (
    <Select onValueChange={onSelect}>
      <SelectTrigger className="w-full">
        <SelectValue placeholder="Select a session" />
      </SelectTrigger>
      <SelectContent>
        {sessions.map(session => (
          <SelectItem key={session.sessionId} value={session.sessionId}>
            {session.sessionName} - {session.focus}
          </SelectItem>
        ))}
      </SelectContent>
    </Select>
  );
}
