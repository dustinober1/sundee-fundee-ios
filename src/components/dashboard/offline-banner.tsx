'use client';

import { WifiOff } from 'lucide-react';
import { useUser } from '@/contexts/user-context';

export function OfflineBanner() {
  const { isOnline } = useUser();

  if (isOnline) return null;

  return (
    <div className="flex items-center gap-2 rounded-md border border-yellow-400 bg-yellow-50 px-3 py-2 text-sm text-yellow-800 dark:bg-yellow-900/20 dark:border-yellow-800 dark:text-yellow-200 mb-4">
      <WifiOff className="h-4 w-4 shrink-0" aria-hidden="true" />
      <span>You&apos;re offline — data will sync when reconnected.</span>
    </div>
  );
}
