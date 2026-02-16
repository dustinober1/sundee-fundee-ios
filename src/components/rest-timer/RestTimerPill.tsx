'use client';

import { useRestTimerContext } from '@/contexts/RestTimerContext';
import { cn } from '@/lib/utils';
import { Timer, ChevronUp } from 'lucide-react';

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

export function RestTimerPill() {
  const { status, remainingSeconds, exerciseName, isExpanded, setExpanded } =
    useRestTimerContext();

  // Don't render if idle or complete
  if (status === 'idle' || status === 'complete') {
    return null;
  }

  return (
    <button
      onClick={() => setExpanded(true)}
      className={cn(
        'fixed bottom-20 left-1/2 -translate-x-1/2 z-40',
        'flex items-center gap-2 px-4 py-2 rounded-full',
        'bg-primary text-primary-foreground shadow-lg',
        'transition-all duration-200',
        'hover:scale-105 active:scale-95',
        remainingSeconds <= 10 && 'animate-pulse'
      )}
      aria-label={`Rest timer: ${formatTime(remainingSeconds)} remaining`}
    >
      <Timer className="h-4 w-4" />
      <span className="font-mono text-sm font-medium">
        {formatTime(remainingSeconds)}
      </span>
      {exerciseName && (
        <span className="text-xs opacity-80 max-w-24 truncate">
          Rest: {exerciseName}
        </span>
      )}
      <ChevronUp className="h-4 w-4 opacity-60" />
    </button>
  );
}
