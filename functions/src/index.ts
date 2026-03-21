import { initializeApp, getApps } from 'firebase-admin/app';

// Initialize Firebase Admin once — guard prevents duplicate init
if (!getApps().length) {
  initializeApp();
}

// Exports added as functions are implemented:
export { generateAIWorkout } from './generateAIWorkout';
// export { createStripeCheckoutSession } from './createCheckoutSession';
// export { stripeWebhook } from './stripeWebhook';
