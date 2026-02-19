'use client';

import { useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';

interface AuthDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess?: () => void;
}

type AuthStep = 'form' | 'email-sent';

export function AuthDialog({ open, onOpenChange, onSuccess }: AuthDialogProps) {
  const [email, setEmail] = useState('');
  const [step, setStep] = useState<AuthStep>('form');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const supabase = createClient();

  async function handleMagicLink(e: React.FormEvent) {
    e.preventDefault();
    if (!email.trim()) return;

    setIsLoading(true);
    setError(null);

    const { error: authError } = await supabase.auth.signInWithOtp({
      email: email.trim(),
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`,
      },
    });

    setIsLoading(false);

    if (authError) {
      setError(authError.message);
      return;
    }

    setStep('email-sent');
    onSuccess?.();
  }

  async function handleGoogleOAuth() {
    setIsLoading(true);
    setError(null);

    const { error: authError } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
      },
    });

    setIsLoading(false);

    if (authError) {
      setError(authError.message);
    }
  }

  function handleClose() {
    setEmail('');
    setStep('form');
    setError(null);
    onOpenChange(false);
  }

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[400px]">
        <DialogHeader>
          <DialogTitle>Sign in to sync your data</DialogTitle>
          <DialogDescription>
            Save your workout history across devices — no password needed.
          </DialogDescription>
        </DialogHeader>

        {step === 'email-sent' ? (
          <div className="space-y-4 py-2">
            <div className="rounded-lg bg-muted p-4 text-center">
              <p className="text-sm font-medium">Check your email</p>
              <p className="text-muted-foreground mt-1 text-sm">
                We sent a sign-in link to <strong>{email}</strong>
              </p>
            </div>
            <Button variant="ghost" className="w-full" onClick={handleClose}>
              Close
            </Button>
          </div>
        ) : (
          <div className="space-y-4 py-2">
            <form onSubmit={handleMagicLink} className="space-y-3">
              <div className="space-y-1.5">
                <Label htmlFor="auth-email">Email address</Label>
                <Input
                  id="auth-email"
                  type="email"
                  placeholder="you@example.com"
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  disabled={isLoading}
                  autoComplete="email"
                />
              </div>
              {error && (
                <p className="text-destructive text-sm">{error}</p>
              )}
              <Button
                type="submit"
                className="w-full"
                disabled={isLoading || !email.trim()}
              >
                {isLoading ? 'Sending…' : 'Send magic link'}
              </Button>
            </form>

            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <span className="w-full border-t" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-background text-muted-foreground px-2">or</span>
              </div>
            </div>

            <Button
              variant="outline"
              className="w-full"
              onClick={handleGoogleOAuth}
              disabled={isLoading}
            >
              <svg className="mr-2 h-4 w-4" viewBox="0 0 24 24" aria-hidden="true">
                <path
                  d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                  fill="#4285F4"
                />
                <path
                  d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                  fill="#34A853"
                />
                <path
                  d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                  fill="#FBBC05"
                />
                <path
                  d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                  fill="#EA4335"
                />
              </svg>
              Continue with Google
            </Button>
          </div>
        )}
      </DialogContent>
    </Dialog>
  );
}
