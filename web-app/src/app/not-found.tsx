import Link from "next/link";

export default function NotFound() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center px-6 text-center">
      <p className="text-gold font-mono text-xs tracking-[0.3em] uppercase mb-4">
        404
      </p>
      <h1 className="!text-4xl !font-bold tracking-tight mb-3">
        Page Not Found
      </h1>
      <p className="text-text-secondary mb-8 max-w-sm">
        The page you&apos;re looking for doesn&apos;t exist or has been moved.
      </p>
      <Link
        href="/"
        className="inline-flex items-center justify-center px-6 py-3 bg-orange text-cream text-sm font-semibold rounded-button hover:opacity-90 transition-opacity"
      >
        Back to Home
      </Link>
    </main>
  );
}
