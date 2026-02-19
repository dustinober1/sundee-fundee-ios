'use client';

import { useState } from 'react';
import { useUser } from '@/contexts/user-context';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import { Button } from '@/components/ui/button';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function formatTimeAgo(date: Date): string {
  const now = Date.now();
  const diffMs = now - date.getTime();
  const diffSec = Math.floor(diffMs / 1000);
  const diffMin = Math.floor(diffSec / 60);
  const diffHr = Math.floor(diffMin / 60);

  if (diffSec < 10) return 'just now';
  if (diffSec < 60) return `${diffSec} sec ago`;
  if (diffMin < 60) return `${diffMin} min ago`;
  if (diffHr < 24) return diffHr === 1 ? '1 hour ago' : `${diffHr} hours ago`;
  const diffDays = Math.floor(diffHr / 24);
  return diffDays === 1 ? '1 day ago' : `${diffDays} days ago`;
}

function getPendingCount(): number {
  try {
    const raw = localStorage.getItem('sync_pending_workout_ids');
    if (!raw) return 0;
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed.length : 0;
  } catch {
    return 0;
  }
}

// ─── Status config ────────────────────────────────────────────────────────────

type SyncStatus = 'synced' | 'syncing' | 'pending' | 'offline' | 'error' | 'disabled';

interface StatusConfig {
  icon: React.ReactNode;
  label: string;
  color: string;
}

function getStatusConfig(status: SyncStatus): StatusConfig {
  switch (status) {
    case 'synced':
      return {
        label: 'Synced',
        color: 'text-green-600 dark:text-green-400',
        icon: (
          <svg
            className="h-4 w-4 text-green-600 dark:text-green-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
        ),
      };
    case 'syncing':
      return {
        label: 'Syncing…',
        color: 'text-blue-600 dark:text-blue-400',
        icon: (
          <svg
            className="h-4 w-4 text-blue-600 dark:text-blue-400 animate-spin"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
            />
          </svg>
        ),
      };
    case 'pending':
      return {
        label: 'Pending',
        color: 'text-yellow-600 dark:text-yellow-400',
        icon: (
          <svg
            className="h-4 w-4 text-yellow-600 dark:text-yellow-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
        ),
      };
    case 'offline':
      return {
        label: 'Offline',
        color: 'text-gray-500 dark:text-gray-400',
        icon: (
          <svg
            className="h-4 w-4 text-gray-500 dark:text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M18.364 5.636a9 9 0 010 12.728M15.536 8.464a5 5 0 010 7.072M6.343 6.343a9 9 0 000 12.728m2.829-2.829a5 5 0 000-7.072M3 3l18 18"
            />
          </svg>
        ),
      };
    case 'error':
      return {
        label: 'Error',
        color: 'text-red-600 dark:text-red-400',
        icon: (
          <svg
            className="h-4 w-4 text-red-600 dark:text-red-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
        ),
      };
    case 'disabled':
    default:
      return {
        label: 'Sync off',
        color: 'text-gray-400 dark:text-gray-500',
        icon: (
          <svg
            className="h-4 w-4 text-gray-400 dark:text-gray-500"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"
            />
          </svg>
        ),
      };
  }
}

// ─── Component ────────────────────────────────────────────────────────────────

export function SyncStatusPopover() {
  const { syncStatus, lastSyncedAt, isAuthenticated, isOnline, pullFromCloud } =
    useUser();
  const [open, setOpen] = useState(false);

  const config = getStatusConfig(syncStatus);
  const pendingCount = getPendingCount();

  async function handleSyncNow() {
    setOpen(false);
    await pullFromCloud();
  }

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <button
          className={`flex items-center gap-1.5 rounded-md px-2 py-1 text-sm font-medium transition-colors hover:bg-muted ${config.color}`}
          aria-label="Sync status"
        >
          {config.icon}
          <span>{config.label}</span>
        </button>
      </PopoverTrigger>

      <PopoverContent className="w-64" align="end">
        {/* Header row */}
        <div className="flex items-center gap-2 mb-3">
          {config.icon}
          <span className={`font-semibold text-sm ${config.color}`}>{config.label}</span>
        </div>

        <div className="space-y-2 text-sm text-muted-foreground">
          {/* Last synced time */}
          {lastSyncedAt ? (
            <p>Last synced: {formatTimeAgo(lastSyncedAt)}</p>
          ) : isAuthenticated ? (
            <p>Not yet synced</p>
          ) : null}

          {/* Pending count */}
          {pendingCount > 0 && (
            <p>
              {pendingCount} workout{pendingCount !== 1 ? 's' : ''} pending upload
            </p>
          )}

          {/* Offline message */}
          {!isOnline && (
            <p className="text-yellow-600 dark:text-yellow-400">
              You&apos;re offline. Data will sync when reconnected.
            </p>
          )}

          {/* Sign-in hint */}
          {!isAuthenticated && (
            <p className="text-muted-foreground">
              Sign in to enable cloud sync across devices.
            </p>
          )}
        </div>

        {/* Sync now button */}
        {isAuthenticated && isOnline && (
          <Button
            size="sm"
            variant="outline"
            className="mt-3 w-full"
            disabled={syncStatus === 'syncing'}
            onClick={handleSyncNow}
          >
            {syncStatus === 'syncing' ? 'Syncing…' : 'Sync now'}
          </Button>
        )}
      </PopoverContent>
    </Popover>
  );
}
