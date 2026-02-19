'use client';

import { useUser } from '@/contexts/user-context';

export function OfflineBanner() {
  const { isOnline } = useUser();

  if (isOnline) return null;

  return (
    <div className="flex items-center gap-2 rounded-md border border-yellow-400 bg-yellow-50 px-3 py-2 text-sm text-yellow-800 dark:bg-yellow-900/20 dark:border-yellow-800 dark:text-yellow-200 mb-4">
      {/* wifi-off icon */}
      <svg
        className="h-4 w-4 shrink-0"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        strokeWidth={2}
        aria-hidden="true"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M18.364 5.636a9 9 0 010 12.728M15.536 8.464a5 5 0 010 7.072M6.343 6.343a9 9 0 000 12.728m2.829-2.829a5 5 0 000-7.072M3 3l18 18"
        />
      </svg>
      <span>You&apos;re offline — data will sync when reconnected.</span>
    </div>
  );
}
