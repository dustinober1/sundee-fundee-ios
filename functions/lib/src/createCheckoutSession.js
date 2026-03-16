"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createCheckoutSession = void 0;
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const stripe_1 = __importDefault(require("stripe"));
const STRIPE_SECRET_KEY = (0, params_1.defineSecret)("STRIPE_SECRET_KEY");
exports.createCheckoutSession = (0, https_1.onCall)({ secrets: [STRIPE_SECRET_KEY] }, async (request) => {
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Must be authenticated");
    }
    const { priceId, successUrl, cancelUrl } = request.data;
    const stripe = new stripe_1.default(STRIPE_SECRET_KEY.value());
    const session = await stripe.checkout.sessions.create({
        mode: "subscription",
        line_items: [{ price: priceId, quantity: 1 }],
        subscription_data: {
            trial_period_days: 7,
            trial_settings: {
                end_behavior: { missing_payment_method: "cancel" },
            },
            metadata: { firebaseUID: request.auth.uid },
        },
        payment_method_collection: "if_required",
        success_url: successUrl,
        cancel_url: cancelUrl,
        metadata: { firebaseUID: request.auth.uid },
    });
    return { url: session.url };
});
//# sourceMappingURL=createCheckoutSession.js.map