import type { SymptomDefinition } from '@/types';

/**
 * Default symptom definitions to seed the database
 */
export const DEFAULT_SYMPTOMS: Omit<SymptomDefinition, 'id' | 'isDefault' | 'userId'>[] = [
  // Physical symptoms
  { name: 'Cramps', category: 'physical' },
  { name: 'Bloating', category: 'physical' },
  { name: 'Breast tenderness', category: 'physical' },
  { name: 'Headaches', category: 'physical' },
  { name: 'Acne', category: 'physical' },
  { name: 'Lower back pain', category: 'physical' },
  { name: 'Joint pain', category: 'physical' },

  // Emotional symptoms
  { name: 'Mood swings', category: 'emotional' },
  { name: 'Anxiety', category: 'emotional' },
  { name: 'Irritability', category: 'emotional' },
  { name: 'Depression', category: 'emotional' },
  { name: 'Feeling overwhelmed', category: 'emotional' },
  { name: 'Low motivation', category: 'emotional' },

  // Energy symptoms
  { name: 'Fatigue', category: 'energy' },
  { name: 'Insomnia', category: 'energy' },
  { name: 'Low energy', category: 'energy' },
  { name: 'High energy', category: 'energy' },
  { name: 'Difficulty concentrating', category: 'energy' },
  { name: 'Food cravings', category: 'energy' },
];
