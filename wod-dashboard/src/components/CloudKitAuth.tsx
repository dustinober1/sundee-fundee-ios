'use client';

import { useState, useEffect, ReactNode } from 'react';

interface CloudKitAuthProps {
  children: ReactNode;
}

export default function CloudKitAuth({ children }: CloudKitAuthProps) {
  const [ready, setReady] = useState(false);
  const [signedIn, setSignedIn] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Wait for CloudKit JS to load
    const checkCloudKit = setInterval(() => {
      if ((window as any).CloudKit) {
        clearInterval(checkCloudKit);
        initCloudKit();
      }
    }, 100);

    // Timeout after 10 seconds
    const timeout = setTimeout(() => {
      clearInterval(checkCloudKit);
      if (!ready) {
        setError('CloudKit JS failed to load. Check your internet connection.');
        setLoading(false);
      }
    }, 10000);

    return () => {
      clearInterval(checkCloudKit);
      clearTimeout(timeout);
    };
  }, []);

  async function initCloudKit() {
    try {
      const CloudKit = (window as any).CloudKit;
      const apiToken = process.env.NEXT_PUBLIC_CLOUDKIT_API_TOKEN;
      const environment = process.env.NEXT_PUBLIC_CLOUDKIT_ENV || 'development';

      if (!apiToken) {
        setError('NEXT_PUBLIC_CLOUDKIT_API_TOKEN not configured');
        setLoading(false);
        return;
      }

      CloudKit.configure({
        containers: [{
          containerIdentifier: 'iCloud.com.sundeefundee.app',
          apiTokenAuth: {
            apiToken,
            persist: true,
          },
          environment,
        }],
      });

      setReady(true);

      // Set up auth - this creates the sign-in button flow
      const container = CloudKit.getDefaultContainer();
      const userIdentity = await container.setUpAuth();

      if (userIdentity) {
        setSignedIn(true);
      }

      setLoading(false);
    } catch (err) {
      console.error('CloudKit init error:', err);
      setError('Failed to initialize CloudKit');
      setLoading(false);
    }
  }

  async function handleSignIn() {
    try {
      setLoading(true);
      const CloudKit = (window as any).CloudKit;
      const container = CloudKit.getDefaultContainer();
      const userIdentity = await container.setUpAuth();
      if (userIdentity) {
        setSignedIn(true);
      }
      setLoading(false);
    } catch (err) {
      console.error('Sign in error:', err);
      setError('Sign in failed');
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[60vh]">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange mx-auto mb-4" />
          <p className="text-navy/60">Connecting to CloudKit...</p>
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
          {/* CloudKit JS renders its own sign-in button into this div */}
          <div id="apple-sign-in-button" />
          <button
            onClick={handleSignIn}
            className="flex items-center gap-2 bg-navy text-cream px-6 py-3 rounded-lg hover:bg-navy/90 font-medium mx-auto"
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
            </svg>
            Sign in with Apple
          </button>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
