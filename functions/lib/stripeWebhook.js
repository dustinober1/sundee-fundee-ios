"use strict";
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
exports.stripeWebhook = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const stripe_1 = __importDefault(require("stripe"));
const logger = __importStar(require("firebase-functions/logger"));
const admin = __importStar(require("firebase-admin"));
const STRIPE_SECRET_KEY = (0, params_1.defineSecret)("STRIPE_SECRET_KEY");
const STRIPE_WEBHOOK_SECRET = (0, params_1.defineSecret)("STRIPE_WEBHOOK_SECRET");
const RC_SECRET_API_KEY = (0, params_1.defineSecret)("RC_SECRET_API_KEY");
const ACTIVE_STATUSES = new Set(["active", "trialing", "past_due"]);
async function grantRCEntitlement(appUserId, rcSecretKey) {
    const url = `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(appUserId)}/entitlements/premium/promotional`;
    try {
        const res = await fetch(url, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${rcSecretKey}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify({ duration: "lifetime" }),
        });
        if (!res.ok) {
            logger.error("RC grant failed", { status: res.status, uid: appUserId });
        }
    }
    catch (err) {
        logger.error("RC grant error", { err, uid: appUserId });
    }
}
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
exports.stripeWebhook = (0, https_1.onRequest)({ secrets: [STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, RC_SECRET_API_KEY] }, async (request, response) => {
    const sig = request.headers["stripe-signature"];
    if (!sig) {
        response.status(400).send("Missing stripe-signature header");
        return;
    }
    const stripe = new stripe_1.default(STRIPE_SECRET_KEY.value());
    let event;
    try {
        event = stripe.webhooks.constructEvent(request.rawBody, sig, STRIPE_WEBHOOK_SECRET.value());
    }
    catch (err) {
        logger.error("Webhook signature verification failed", err);
        response.status(400).send("Webhook signature verification failed");
        return;
    }
    const subscription = event.data.object;
    const firebaseUID = subscription.metadata?.firebaseUID;
    if (!firebaseUID) {
        logger.warn("No firebaseUID in subscription metadata", { type: event.type });
        response.json({ received: true });
        return;
    }
    const rcKey = RC_SECRET_API_KEY.value();
    if (event.type === "customer.subscription.created" ||
        event.type === "customer.subscription.updated") {
        if (ACTIVE_STATUSES.has(subscription.status)) {
            await grantRCEntitlement(firebaseUID, rcKey);
            try {
                await admin
                    .firestore()
                    .doc(`users/${firebaseUID}`)
                    .set({
                    premiumEntitlement: { active: true, expiresAt: null, source: "stripe" },
                    stripeSubscriptionId: subscription.id,
                }, { merge: true });
            }
            catch (err) {
                logger.error("Firestore grant write failed", { err, uid: firebaseUID });
            }
        }
        else {
            await revokeRCEntitlement(firebaseUID, rcKey);
            try {
                await admin
                    .firestore()
                    .doc(`users/${firebaseUID}`)
                    .set({
                    premiumEntitlement: {
                        active: false,
                        expiresAt: admin.firestore.Timestamp.now(),
                        source: "stripe",
                    },
                }, { merge: true });
            }
            catch (err) {
                logger.error("Firestore revoke write failed", { err, uid: firebaseUID });
            }
        }
    }
    else if (event.type === "customer.subscription.deleted") {
        await revokeRCEntitlement(firebaseUID, rcKey);
        try {
            await admin
                .firestore()
                .doc(`users/${firebaseUID}`)
                .set({
                premiumEntitlement: {
                    active: false,
                    expiresAt: admin.firestore.Timestamp.now(),
                    source: "stripe",
                },
            }, { merge: true });
        }
        catch (err) {
            logger.error("Firestore revoke write failed", { err, uid: firebaseUID });
        }
    }
    response.json({ received: true });
});
//# sourceMappingURL=stripeWebhook.js.map