import { Redirect } from 'expo-router';
import { useUser } from '@/contexts/user-context';
import { ActivityIndicator, View } from 'react-native';

export default function HomePage() {
  const { user } = useUser();

  if (!user) {
    return <Redirect href="/onboarding" />;
  }

  return <Redirect href="/(tabs)/dashboard" />;
}
