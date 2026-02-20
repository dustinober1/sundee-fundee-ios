export default function OfflinePage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-6 p-8 text-center">
      <div className="flex h-20 w-20 items-center justify-center rounded-full bg-muted">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="40"
          height="40"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="text-muted-foreground"
          aria-hidden="true"
        >
          <line x1="1" y1="1" x2="23" y2="23" />
          <path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55" />
          <path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39" />
          <path d="M10.71 5.05A16 16 0 0 1 22.56 9" />
          <path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88" />
          <path d="M8.53 16.11a6 6 0 0 1 6.95 0" />
          <line x1="12" y1="20" x2="12.01" y2="20" />
        </svg>
      </div>

      <div className="space-y-2">
        <h1 className="text-2xl font-bold tracking-tight">You&apos;re offline</h1>
        <p className="text-muted-foreground max-w-sm">
          No internet connection detected. Your workout data is saved locally
          and will sync when you&apos;re back online.
        </p>
      </div>

      <div className="rounded-lg border bg-card p-4 text-sm text-muted-foreground max-w-sm w-full">
        <p className="font-medium text-foreground mb-1">What still works offline:</p>
        <ul className="space-y-1 text-left list-disc list-inside">
          <li>Log and track workouts</li>
          <li>View your exercise history</li>
          <li>Browse cached pages</li>
        </ul>
      </div>

      <button
        onClick={() => window.location.reload()}
        className="rounded-md bg-primary px-6 py-2.5 text-sm font-medium text-primary-foreground hover:bg-primary/90 transition-colors"
      >
        Try again
      </button>
    </div>
  );
}
