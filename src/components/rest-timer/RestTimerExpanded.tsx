'use client';

import { useRestTimerContext } from '@/contexts/RestTimerContext';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { X, Play, Pause, SkipForward, Plus, Minus } from 'lucide-react';

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

export function RestTimerExpanded() {
  const {
    status,
    remainingSeconds,
    durationSeconds,
    exerciseName,
    isExpanded,
    pause,
    resume,
    addTime,
    subtractTime,
    cancel,
    skip,
    setExpanded,
  } = useRestTimerContext();

  if (!isExpanded) {
    return null;
  }

  const handleClose = () => {
    setExpanded(false);
  };

  const handleCancel = () => {
    cancel();
    setExpanded(false);
  };

  // Calculate progress for circular indicator
  const progress = durationSeconds > 0 ? remainingSeconds / durationSeconds : 0;
  const circumference = 2 * Math.PI * 90; // radius = 90
  const strokeDashoffset = circumference * (1 - progress);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm"
      onClick={handleClose}
    >
      <div
        className={cn(
          'bg-card rounded-2xl p-6 w-[90%] max-w-sm',
          'flex flex-col items-center gap-6',
          'animate-in fade-in zoom-in-95 duration-200'
        )}
        onClick={e => e.stopPropagation()}
      >
        {/* Close button */}
        <button
          onClick={handleClose}
          className="absolute top-4 right-4 p-2 rounded-full hover:bg-muted"
          aria-label="Close"
        >
          <X className="h-5 w-5" />
        </button>

        {/* Circular progress with time */}
        <div className="relative w-48 h-48">
          <svg className="w-full h-full -rotate-90">
            {/* Background circle */}
            <circle
              cx="96"
              cy="96"
              r="90"
              stroke="currentColor"
              strokeWidth="8"
              fill="none"
              className="text-muted"
            />
            {/* Progress circle */}
            <circle
              cx="96"
              cy="96"
              r="90"
              stroke="currentColor"
              strokeWidth="8"
              fill="none"
              className="text-primary transition-all duration-1000"
              strokeLinecap="round"
              strokeDasharray={circumference}
              strokeDashoffset={strokeDashoffset}
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-4xl font-mono font-bold">
              {formatTime(remainingSeconds)}
            </span>
          </div>
        </div>

        {/* Exercise info */}
        <div className="text-center">
          <p className="font-medium">{exerciseName || 'Rest'}</p>
          <p className="text-sm text-muted-foreground">
            Prescribed: {formatTime(durationSeconds)}
          </p>
        </div>

        {/* Time adjustment buttons */}
        <div className="flex items-center gap-4">
          <Button
            variant="outline"
            size="sm"
            onClick={() => subtractTime(30)}
            disabled={remainingSeconds < 30}
          >
            <Minus className="h-4 w-4 mr-1" />
            -30s
          </Button>
          <Button variant="outline" size="sm" onClick={() => addTime(30)}>
            <Plus className="h-4 w-4 mr-1" />
            +30s
          </Button>
        </div>

        {/* Control buttons */}
        <div className="flex items-center gap-4">
          {status === 'running' ? (
            <Button variant="secondary" onClick={pause}>
              <Pause className="h-4 w-4 mr-2" />
              Pause
            </Button>
          ) : (
            <Button variant="secondary" onClick={resume}>
              <Play className="h-4 w-4 mr-2" />
              Resume
            </Button>
          )}
          <Button variant="default" onClick={skip}>
            <SkipForward className="h-4 w-4 mr-2" />
            Skip
          </Button>
        </div>

        {/* Cancel button */}
        <Button variant="ghost" onClick={handleCancel}>
          Cancel
        </Button>
      </div>
    </div>
  );
}
