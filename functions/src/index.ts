import { initializeApp, getApps } from 'firebase-admin/app';

// Initialize Firebase Admin once — guard prevents duplicate init
if (!getApps().length) {
  initializeApp();
}

export { generateAIWorkout } from './generateAIWorkout';
export { createStripeCheckoutSession, createStripePortalSession } from './createCheckoutSession';
export { stripeWebhook } from './stripeWebhook';
