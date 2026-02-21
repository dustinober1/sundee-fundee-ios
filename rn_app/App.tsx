import React, { useEffect, useState } from 'react';
import { SafeAreaView, StyleSheet } from 'react-native';
import { initDb } from './src/lib/db';
import OnboardingScreen from './src/screens/OnboardingScreen';
import ProgramListScreen from './src/screens/ProgramListScreen';
import SignInScreen from './src/screens/SignInScreen';

export default function App() {
  const [screen, setScreen] = useState<'onboarding'|'programs'|'signin'>('onboarding');
  const [selectedProgram, setSelectedProgram] = useState<string | null>(null);

  useEffect(() => {
    initDb().catch(err => console.warn('DB init error', err));
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      {screen === 'onboarding' && <OnboardingScreen onContinue={() => setScreen('programs')} onSignIn={() => setScreen('signin')} />}
      {screen === 'signin' && <SignInScreen onSignedIn={() => setScreen('programs')} onBack={() => setScreen('onboarding')} />}
      {screen === 'programs' && (
        <ProgramListScreen
          onBack={() => setScreen('onboarding')}
          onSelect={(id) => {
            setSelectedProgram(id);
            // TODO: navigate to program details
          }}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
});
