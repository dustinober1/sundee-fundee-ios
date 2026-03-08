'use client';

import { useState, useEffect, useRef, ReactNode } from 'react';

interface CloudKitAuthProps {
  children: ReactNode;
}

export default function CloudKitAuth({ children }: CloudKitAuthProps) {
  const [signedIn, setSignedIn] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const initAttempted = useRef(false);

  useEffect(() => {
    if (initAttempted.current) return;
    initAttempted.current = true;

    let cancelled = false;

    async function loadAndInit() {
      // Wait for CloudKit JS to be available (loaded via script tag in layout)
      const cloudKit = await waitForCloudKit(15000);
      if (cancelled) return;

      if (!cloudKit) {
        setError('CloudKit JS failed to load. Check your internet connection.');
        setLoading(false);
        return;
      }

      try {
        const apiToken = process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN;
        const environment = process.env.NEXT_PUBLIC_CLOUDKIT_ENV || 'development';

        if (!apiToken) {
          setError('NEXT_PUBLIC_CLOUDKIT_API_TOKEN not configured');
          setLoading(false);
          return;
        }

        cloudKit.configure({
          containers: [{
            containerIdentifier: 'iCloud.com.sundeefundee.app',
            apiTokenAuth: {
              apiToken,
              persist: true,
              signInButton: {
                id: 'apple-sign-in-button',
                theme: 'black',
              },
              signOutButton: {
                id: 'apple-sign-out-button',
                theme: 'black',
              },
            },
            environment,
          }],
        });

        const container = cloudKit.getDefaultContainer();

        // setUpAuth returns the current user identity if already signed in
        const userIdentity = await container.setUpAuth();

        if (cancelled) return;

        if (userIdentity) {
          setSignedIn(true);
        }

        // Listen for auth state changes
        container.whenUserSignsIn().then(() => {
          if (!cancelled) setSignedIn(true);
        });
        container.whenUserSignsOut().then(() => {
          if (!cancelled) {
            setSignedIn(false);
          }
        });

        setLoading(false);
      } catch (err) {
        if (cancelled) return;
        console.error('CloudKit init error:', err);
        setError(`Failed to initialize CloudKit: ${err}`);
        setLoading(false);
      }
    }

    loadAndInit();

    return () => {
      cancelled = true;
    };
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange mx-auto mb-4" />
          <p className="text-navy/60">Connecting to CloudKit...</p>
          {/* These divs must exist in the DOM for CloudKit JS to render buttons into */}
          <div id="apple-sign-in-button" className="hidden" />
          <div id="apple-sign-out-button" className="hidden" />
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center art-deco-card p-8 max-w-md">
          <p className="text-red-600 font-medium mb-2">Connection Error</p>
          <p className="text-navy/60 text-sm">{error}</p>
          <button
            onClick={() => window.location.reload()}
            className="mt-4 px-4 py-2 bg-orange text-cream rounded-lg hover:bg-orange/90"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (!signedIn) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center art-deco-card p-8 max-w-md">
          <h2 className="text-2xl font-serif font-bold text-navy mb-2">WOD Dashboard</h2>
          <p className="text-navy/60 mb-6">Sign in with your Apple ID to manage workouts</p>
          {/* CloudKit JS renders its sign-in button into this div */}
          <div id="apple-sign-in-button" className="flex justify-center" />
          <div id="apple-sign-out-button" className="hidden" />
        </div>
      </div>
    );
  }

  return (
    <>
      <div id="apple-sign-in-button" className="hidden" />
      <div id="apple-sign-out-button" className="hidden" />
      {children}
    </>
  );
}

function waitForCloudKit(timeoutMs: number): Promise<any | null> {
  return new Promise((resolve) => {
    // Check immediately
    if ((window as any).CloudKit) {
      resolve((window as any).CloudKit);
      return;
    }

    const interval = setInterval(() => {
      if ((window as any).CloudKit) {
        clearInterval(interval);
        clearTimeout(timeout);
        resolve((window as any).CloudKit);
      }
    }, 100);

    const timeout = setTimeout(() => {
      clearInterval(interval);
      resolve(null);
    }, timeoutMs);
  });
}
