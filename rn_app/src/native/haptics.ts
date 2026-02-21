import * as Haptics from 'expo-haptics';

export async function triggerSetLoggedHaptic(): Promise<void> {
  await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
}
