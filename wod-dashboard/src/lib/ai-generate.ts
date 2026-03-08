import { WODFormData } from '@/types/wod';

export async function generateWorkout(prompt: string): Promise<Partial<WODFormData>> {
  const response = await fetch('/api/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ prompt }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to generate workout');
  }

  return response.json();
}

// Detect if input is structured (use parser) or intent-based (use AI)
export function isStructuredInput(text: string): boolean {
  // Structured: contains sets x reps patterns, specific exercise names with numbers
  const structuredPatterns = [
    /\d+x\d+/i,           // 5x5, 3x10
    /\d+\s*sets?/i,        // 5 sets
    /\d+\s*reps?/i,        // 10 reps
    /\d+%/,                // 75%
    /AMRAP\s+\d+/i,        // AMRAP 12
    /EMOM\s+\d+/i,         // EMOM 20
  ];
  return structuredPatterns.some(p => p.test(text));
}
