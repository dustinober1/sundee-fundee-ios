import React from 'react';
import { View, Text, StyleSheet, Button } from 'react-native';

export default function OnboardingScreen({ onContinue, onSignIn }: { onContinue: () => void; onSignIn?: () => void }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Welcome to Sundee-Fundee</Text>
      <Text style={styles.subtitle}>Track workouts, cycles, and progress — offline-first.</Text>
      <Button title="Get Started" onPress={onContinue} />
      {onSignIn ? <View style={{ marginTop: 12 }}><Button title="Sign in" onPress={onSignIn} /></View> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, padding: 16, justifyContent: 'center', alignItems: 'center' },
  title: { fontSize: 24, fontWeight: '700', marginBottom: 8 },
  subtitle: { fontSize: 16, color: '#444', marginBottom: 16, textAlign: 'center' }
});
