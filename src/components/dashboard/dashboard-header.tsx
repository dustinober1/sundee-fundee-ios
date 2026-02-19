'use client';

import { useState } from 'react';
import { useUser } from '@/contexts/user-context';
import { SyncStatusPopover } from './sync-status-popover';
import { AuthDialog } from '@/components/auth/auth-dialog';
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from '@/components/ui/popover';
import { Button } from '@/components/ui/button';

function getInitials(name: string): string {
  return name
    .split(' ')
    .map((part) => part[0] ?? '')
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

export function DashboardHeader() {
  const { user, isAuthenticated, authUser, signOut } = useUser();
  const [authOpen, setAuthOpen] = useState(false);
  const [avatarOpen, setAvatarOpen] = useState(false);

  const displayName = user?.name ?? authUser?.email ?? '';
  const email = authUser?.email ?? '';
  const initials = displayName ? getInitials(displayName) : '?';

  async function handleSignOut() {
    setAvatarOpen(false);
    await signOut();
  }

  return (
    <div className="flex items-center justify-between mb-4">
      <h1 className="text-2xl font-bold">Dashboard</h1>

      <div className="flex items-center gap-2">
        {/* Sync status indicator */}
        <SyncStatusPopover />

        {/* User avatar / sign-in */}
        {isAuthenticated ? (
          <Popover open={avatarOpen} onOpenChange={setAvatarOpen}>
            <PopoverTrigger asChild>
              <button
                className="flex h-8 w-8 items-center justify-center rounded-full bg-primary text-primary-foreground text-sm font-semibold transition-opacity hover:opacity-80"
                aria-label="Account menu"
              >
                {initials}
              </button>
            </PopoverTrigger>

            <PopoverContent className="w-56" align="end">
              <div className="mb-3 space-y-0.5">
                {displayName && (
                  <p className="text-sm font-semibold leading-tight">{displayName}</p>
                )}
                {email && (
                  <p className="text-xs text-muted-foreground truncate">{email}</p>
                )}
              </div>
              <Button
                size="sm"
                variant="outline"
                className="w-full"
                onClick={handleSignOut}
              >
                Sign out
              </Button>
            </PopoverContent>
          </Popover>
        ) : (
          <>
            <Button
              size="sm"
              variant="outline"
              onClick={() => setAuthOpen(true)}
            >
              Sign in
            </Button>
            <AuthDialog
              open={authOpen}
              onOpenChange={setAuthOpen}
            />
          </>
        )}
      </div>
    </div>
  );
}
