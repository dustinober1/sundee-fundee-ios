"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.checkRateLimit = checkRateLimit;
const firestore_1 = require("firebase-admin/firestore");
const TIER_LIMITS = {
    plus: 1,
    premium: 10,
};
async function checkRateLimit(userId, tier) {
    const db = (0, firestore_1.getFirestore)();
    const today = new Date().toISOString().split("T")[0];
    const limit = TIER_LIMITS[tier] ?? 0;
    if (limit === 0) {
        return { allowed: false, remaining: 0 };
    }
    const usageRef = db.collection("users").doc(userId).collection("aiUsage").doc(today);
    const usageDoc = await usageRef.get();
    const current = usageDoc.data()?.count ?? 0;
    if (current >= limit) {
        const tomorrow = new Date();
        tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
        tomorrow.setUTCHours(0, 0, 0, 0);
        return { allowed: false, remaining: 0, resetsAt: tomorrow.toISOString() };
    }
    await usageRef.set({ count: current + 1, updatedAt: new Date() }, { merge: true });
    return { allowed: true, remaining: limit - current - 1 };
}
//# sourceMappingURL=rate-limit.js.map