import * as admin from "firebase-admin";

admin.initializeApp();

export { generateWorkout } from "./generateWorkout";
export { createCheckoutSession } from "./createCheckoutSession";
export { stripeWebhook } from "./stripeWebhook";
export { deleteAccount } from "./deleteAccount";
