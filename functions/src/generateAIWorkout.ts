// Placeholder — full implementation added in Task 2
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

const geminiApiKey = defineSecret('GEMINI_API_KEY');

export const generateAIWorkout = onCall(
  { secrets: [geminiApiKey], region: 'us-central1' },
  async (_request) => {
    throw new HttpsError('unimplemented', 'Not yet implemented.');
  }
);
