/**
 * app/(onboarding)/_layout.tsx — Onboarding route group layout.
 *
 * Wraps all onboarding step screens in OnboardingProvider so draft state
 * is shared across steps. Uses a headerless Stack navigator.
 */
import { Stack } from 'expo-router';
import { OnboardingProvider } from '@/src/onboarding/OnboardingContext';

export default function OnboardingLayout(): React.JSX.Element {
  return (
    <OnboardingProvider>
      <Stack screenOptions={{ headerShown: false }} />
    </OnboardingProvider>
  );
}
