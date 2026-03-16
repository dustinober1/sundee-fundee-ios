"use strict";
/**
 * deleteAccount Cloud Function
 *
 * Callable function that performs a full account deletion:
 *   1. Revoke RevenueCat entitlement (best-effort)
 *   2. Cancel Stripe subscription if stripeSubscriptionId exists (best-effort)
 *   3. Recursively delete all Firestore data under /users/{uid}
 *   4. Delete Firebase Auth user
 *
 * Requires the caller to be authenticated. Unauthenticated requests
 * are rejected with an HttpsError('unauthenticated') immediately.
 *
 * Steps 1 and 2 are best-effort: errors are logged but do not abort
 * the deletion. The user's data is always removed from Firestore and
 * Auth regardless of external API failures.
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteAccount = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const stripe_1 = __importDefault(require("stripe"));
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const STRIPE_SECRET_KEY = (0, params_1.defineSecret)("STRIPE_SECRET_KEY");
const RC_SECRET_API_KEY = (0, params_1.defineSecret)("RC_SECRET_API_KEY");
/**
 * Revoke the RevenueCat premium entitlement for a user.
 * Best-effort: catches and logs errors, never throws.
 */
async function revokeRCEntitlement(appUserId, rcSecretKey) {
    const url = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}/entitlements/premium/promotional`;
    try {
        const res = await fetch(url, {
            method: "DELETE",
            headers: {
                Authorization: `Bearer ${rcSecretKey}`,
            },
        });
        if (!res.ok) {
            logger.error("RC revoke failed", { status: res.status, uid: appUserId });
        }
    }
    catch (err) {
        logger.error("RC revoke error", { err, uid: appUserId });
    }
}
exports.deleteAccount = (0, https_1.onCall)({
    secrets: [STRIPE_SECRET_KEY, RC_SECRET_API_KEY],
    timeoutSeconds: 540,
}, async (request) => {
    // Authentication guard
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Must be authenticated to delete account");
    }
    const uid = request.auth.uid;
    const db = admin.firestore();
    // Step 1: Revoke RevenueCat entitlement (best-effort)
    await revokeRCEntitlement(uid, RC_SECRET_API_KEY.value());
    // Step 2: Cancel Stripe subscription (best-effort)
    try {
        const userDoc = await db.doc(`users/${uid}`).get();
        const userData = userDoc.data();
        const stripeSubscriptionId = userData?.stripeSubscriptionId;
        if (stripeSubscriptionId) {
            const stripe = new stripe_1.default(STRIPE_SECRET_KEY.value());
            await stripe.subscriptions.cancel(stripeSubscriptionId);
        }
    }
    catch (err) {
        logger.error("Stripe cancel error during account deletion", { err, uid });
    }
    // Step 3: Recursively delete all Firestore data under /users/{uid}
    await db.recursiveDelete(db.doc(`users/${uid}`));
    // Step 4: Delete Firebase Auth user
    await admin.auth().deleteUser(uid);
    return { success: true };
});
//# sourceMappingURL=deleteAccount.js.map