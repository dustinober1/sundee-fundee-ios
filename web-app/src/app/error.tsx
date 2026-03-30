"use client";

export default function Error({
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center px-6 text-center">
      <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-4">
        Error
      </p>
      <h1 className="!text-4xl !font-bold tracking-tight mb-3">
        Something Went Wrong
      </h1>
      <p className="text-text-secondary mb-8 max-w-sm">
        An unexpected error occurred. Please try again.
      </p>
      <button
        onClick={reset}
        className="inline-flex items-center justify-center px-6 py-3 bg-orange text-cream text-sm font-semibold rounded-button hover:opacity-90 transition-opacity"
      >
        Try Again
      </button>
    </main>
  );
}
