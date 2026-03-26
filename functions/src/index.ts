import * as admin from "firebase-admin";

admin.initializeApp();

export { generateWorkout } from "./generateWorkout";
export { siwaExchangeCode, siwaRevokeToken } from "./siwaRevocation";
