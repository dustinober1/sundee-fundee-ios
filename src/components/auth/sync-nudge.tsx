'use client';

import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { AuthDialog } from '@/components/auth/auth-dialog';

type NudgeStep = 'nudge' | 'auth' | 'upload-prompt' | 'uploading' | 'done';

interface SyncNudgeProps {
  /** Whether to show the nudge at all */
  show: boolean;
  /** Whether user is currently authenticated */
  isAuthenticated: boolean;
  /** Called to upload local data to cloud; returns success */
  uploadExistingData: () => Promise<boolean>;
  /** Called when the nudge flow completes (uploaded or skipped) */
  onComplete?: () => void;
}

/**
 * SyncNudge — full flow component.
 * Guides user: nudge → auth dialog → "upload existing data?" → done
 */
export function SyncNudge({
  show,
  isAuthenticated,
  uploadExistingData,
  onComplete,
}: SyncNudgeProps) {
  const [step, setStep] = useState<NudgeStep>('nudge');
  const [authDialogOpen, setAuthDialogOpen] = useState(false);
  const [uploadError, setUploadError] = useState(false);

  if (!show) return null;
  if (step === 'done') return null;

  // If already authenticated and we're in nudge/auth step, jump to upload-prompt
  const effectiveStep: NudgeStep = isAuthenticated && (step === 'nudge' || step === 'auth')
    ? 'upload-prompt'
    : step;

  async function handleUpload() {
    setStep('uploading');
    setUploadError(false);
    const success = await uploadExistingData();
    if (success) {
      setStep('done');
      onComplete?.();
    } else {
      setUploadError(true);
      setStep('upload-prompt');
    }
  }

  function handleSkip() {
    setStep('done');
    onComplete?.();
  }

  function handleAuthSuccess() {
    setAuthDialogOpen(false);
    setStep('upload-prompt');
  }

  if (effectiveStep === 'nudge') {
    return (
      <>
        <Card className="border-primary/30 bg-primary/5">
          <CardHeader className="pb-3">
            <CardTitle className="text-base">Sync your workouts</CardTitle>
            <CardDescription>
              Back up your progress and access it from any device.
            </CardDescription>
          </CardHeader>
          <CardContent className="flex gap-2">
            <Button
              size="sm"
              onClick={() => {
                setStep('auth');
                setAuthDialogOpen(true);
              }}
            >
              Enable sync
            </Button>
            <Button size="sm" variant="ghost" onClick={handleSkip}>
              Not now
            </Button>
          </CardContent>
        </Card>

        <AuthDialog
          open={authDialogOpen}
          onOpenChange={open => {
            setAuthDialogOpen(open);
            if (!open && step === 'auth') setStep('nudge');
          }}
          onSuccess={handleAuthSuccess}
        />
      </>
    );
  }

  if (effectiveStep === 'upload-prompt') {
    return (
      <Card className="border-primary/30 bg-primary/5">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">Upload existing data?</CardTitle>
          <CardDescription>
            You have workout history saved locally. Would you like to upload it to the cloud?
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-2">
          {uploadError && (
            <p className="text-destructive text-sm">
              Upload failed. Please try again.
            </p>
          )}
          <div className="flex gap-2">
            <Button size="sm" onClick={handleUpload}>
              Upload existing data
            </Button>
            <Button size="sm" variant="ghost" onClick={handleSkip}>
              Skip
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (effectiveStep === 'uploading') {
    return (
      <Card className="border-primary/30 bg-primary/5">
        <CardContent className="py-4">
          <p className="text-muted-foreground text-sm">Uploading your data…</p>
        </CardContent>
      </Card>
    );
  }

  return null;
}

interface SyncNudgeCardProps {
  /** Whether to show the card */
  show: boolean;
  /** Whether user is currently authenticated */
  isAuthenticated: boolean;
  /** Called to upload local data to cloud; returns success */
  uploadExistingData: () => Promise<boolean>;
  /** Called when flow completes */
  onComplete?: () => void;
}

/**
 * SyncNudgeCard — simplified dashboard card version of the sync nudge.
 * Same flow, slightly more compact for embedding in a dashboard grid.
 */
export function SyncNudgeCard({
  show,
  isAuthenticated,
  uploadExistingData,
  onComplete,
}: SyncNudgeCardProps) {
  const [authDialogOpen, setAuthDialogOpen] = useState(false);
  const [uploaded, setUploaded] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [showUploadPrompt, setShowUploadPrompt] = useState(isAuthenticated);

  if (!show || uploaded) return null;

  async function handleUpload() {
    setUploading(true);
    const success = await uploadExistingData();
    setUploading(false);
    if (success) {
      setUploaded(true);
      onComplete?.();
    }
  }

  if (showUploadPrompt) {
    return (
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium">Upload existing data?</CardTitle>
        </CardHeader>
        <CardContent className="flex gap-2">
          <Button size="sm" onClick={handleUpload} disabled={uploading}>
            {uploading ? 'Uploading…' : 'Upload'}
          </Button>
          <Button size="sm" variant="ghost" onClick={() => { setUploaded(true); onComplete?.(); }}>
            Skip
          </Button>
        </CardContent>
      </Card>
    );
  }

  return (
    <>
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-sm font-medium">Enable cloud sync</CardTitle>
          <CardDescription className="text-xs">
            Back up your workouts automatically.
          </CardDescription>
        </CardHeader>
        <CardContent className="flex gap-2">
          <Button size="sm" onClick={() => setAuthDialogOpen(true)}>
            Sign in
          </Button>
        </CardContent>
      </Card>

      <AuthDialog
        open={authDialogOpen}
        onOpenChange={setAuthDialogOpen}
        onSuccess={() => {
          setAuthDialogOpen(false);
          setShowUploadPrompt(true);
        }}
      />
    </>
  );
}
