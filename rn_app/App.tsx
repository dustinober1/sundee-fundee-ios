import 'react-native-gesture-handler';
import React, { useEffect, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import {
  createNativeStackNavigator,
  type NativeStackScreenProps,
} from '@react-navigation/native-stack';
import { initDb } from './src/lib/db';
import ProgramDetailScreen from './src/screens/ProgramDetailScreen';
import OnboardingScreen from './src/screens/OnboardingScreen';
import ProgramListScreen from './src/screens/ProgramListScreen';
import ProgressScreen from './src/screens/ProgressScreen';
import SignInScreen from './src/screens/SignInScreen';
import WorkoutScreen from './src/screens/WorkoutScreen';
import { scheduleBackgroundSync } from './src/lib/sync';
import { artDecoTheme } from './src/theme/tokens';

type RootStackParamList = {
  Onboarding: undefined;
  SignIn: undefined;
  Programs: undefined;
  ProgramDetail: { programId: string };
  Workout: { programId: string };
  Progress: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function App() {
  const [isReady, setIsReady] = useState(false);
  useEffect(() => {
    let stopSync: (() => void) | null = null;
    let isMounted = true;

    const bootstrap = async () => {
      await initDb();
      stopSync = scheduleBackgroundSync();
      if (isMounted) setIsReady(true);
    };

    bootstrap().catch(error => {
      console.warn('App bootstrap failed', error);
      if (isMounted) setIsReady(true);
    });

    return () => {
      isMounted = false;
      if (stopSync) stopSync();
    };
  }, []);

  if (!isReady) return null;

  return (
    <NavigationContainer>
      <Stack.Navigator
        initialRouteName="Onboarding"
        screenOptions={{
          headerStyle: { backgroundColor: artDecoTheme.colors.surface },
          headerTintColor: artDecoTheme.colors.textPrimary,
          contentStyle: { backgroundColor: artDecoTheme.colors.background },
        }}
      >
        <Stack.Screen
          name="Onboarding"
          options={{ headerShown: false }}
        >
          {({ navigation }) => (
            <OnboardingScreen
              onContinue={() => navigation.replace('Programs')}
              onSignIn={() => navigation.navigate('SignIn')}
            />
          )}
        </Stack.Screen>
        <Stack.Screen name="SignIn" options={{ title: 'Account' }}>
          {({ navigation }) => (
            <SignInScreen
              onSignedIn={() => navigation.replace('Programs')}
              onBack={() => navigation.goBack()}
            />
          )}
        </Stack.Screen>
        <Stack.Screen name="Programs" options={{ title: 'Programs' }}>
          {({ navigation }) => (
            <ProgramListScreen
              onSelect={programId => navigation.navigate('ProgramDetail', { programId })}
              onViewProgress={() => navigation.navigate('Progress')}
            />
          )}
        </Stack.Screen>
        <Stack.Screen name="ProgramDetail" options={{ title: 'Program Details' }}>
          {({
            navigation,
            route,
          }: NativeStackScreenProps<RootStackParamList, 'ProgramDetail'>) => (
            <ProgramDetailScreen
              programId={route.params.programId}
              onStartWorkout={programId =>
                navigation.navigate('Workout', { programId })
              }
            />
          )}
        </Stack.Screen>
        <Stack.Screen name="Workout" options={{ title: 'Workout Session' }}>
          {({
            navigation,
            route,
          }: NativeStackScreenProps<RootStackParamList, 'Workout'>) => (
            <WorkoutScreen
              programId={route.params.programId}
              onWorkoutCompleted={() => navigation.navigate('Progress')}
            />
          )}
        </Stack.Screen>
        <Stack.Screen name="Progress" component={ProgressScreen} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
