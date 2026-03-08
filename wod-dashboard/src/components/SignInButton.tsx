'use client';

import { useState } from 'react';

interface SignInButtonProps {
  onSignIn: (userID: string) => void;
}

export default function SignInButton({ onSignIn }: SignInButtonProps) {
  const [loading, setLoading] = useState(false);

  const handleSignIn = async () => {
    setLoading(true);
    try {
      // Apple Sign In JS SDK will be loaded via script tag
      // For now, create a placeholder that will be connected when
      // Apple Developer Console is configured
      const AppleID = (window as unknown as { AppleID?: { auth: { init: (config: object) => Promise<void>; signIn: () => Promise<{ authorization?: { id_token?: string } }> } } }).AppleID;
      if (!AppleID) {
        console.error('Apple Sign In SDK not loaded');
        return;
      }

      await AppleID.auth.init({
        clientId: process.env.NEXT_PUBLIC_APPLE_CLIENT_ID,
        redirectURI: process.env.NEXT_PUBLIC_APPLE_REDIRECT_URI,
        scope: 'name email',
        usePopup: true,
      });

      const response = await AppleID.auth.signIn();
      const userID = response.authorization?.id_token
        ? JSON.parse(atob(response.authorization.id_token.split('.')[1])).sub
        : null;

      if (userID) {
        onSignIn(userID);
      }
    } catch (error) {
      console.error('Apple Sign In failed:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <button
      onClick={handleSignIn}
      disabled={loading}
      className="flex items-center gap-2 bg-navy text-cream px-6 py-3 rounded-lg hover:bg-navy-light disabled:opacity-50 font-medium shadow-md transition-colors"
    >
      <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
        <path d="M17.05 20.28c-.98.95-2.05.88-3.08.4-1.09-.5-2.08-.48-3.24 0-1.44.62-2.2.44-3.06-.4C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
      </svg>
      {loading ? 'Signing in...' : 'Sign in with Apple'}
    </button>
  );
}
