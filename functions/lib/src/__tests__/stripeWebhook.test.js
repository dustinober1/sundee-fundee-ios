"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const stripe_1 = require("../../__mocks__/stripe");
const firebase_admin_1 = __importDefault(require("../../__mocks__/firebase-admin"));
// We need a mutable reference to the set mock so we can verify calls
let mockDocSet;
beforeEach(() => {
    jest.clearAllMocks();
    // Re-build the firestore mock so we can capture doc().set calls
    mockDocSet = jest.fn().mockResolvedValue(undefined);
    const mockDoc = jest.fn(() => ({ set: mockDocSet }));
    const mockFirestoreInstance = {
        collection: jest.fn(() => ({ doc: jest.fn(() => ({ id: "mock-id" })) })),
        doc: mockDoc,
    };
    firebase_admin_1.default.firestore.mockReturnValue(mockFirestoreInstance);
    firebase_admin_1.default.firestore.Timestamp = {
        now: jest.fn(() => ({ _seconds: 1234567890, _nanoseconds: 0 })),
    };
});
// Stub global fetch for RC API calls
const mockFetch = jest.spyOn(global, "fetch").mockImplementation(jest.fn().mockResolvedValue({ ok: true, status: 200 }));
// stripeWebhook is an onRequest handler — the mock returns it directly
const { stripeWebhook } = require("../stripeWebhook");
function makeReq(overrides = {}) {
    const defaultHeaders = { "stripe-signature": "valid-sig" };
    return {
        headers: overrides.headers !== undefined ? overrides.headers : defaultHeaders,
        rawBody: overrides.rawBody ?? Buffer.from("{}"),
    };
}
function makeRes() {
    const res = {
        status: jest.fn().mockReturnThis(),
        send: jest.fn().mockReturnThis(),
        json: jest.fn().mockReturnThis(),
    };
    return res;
}
describe("stripeWebhook", () => {
    it("returns 400 when stripe-signature header is missing", async () => {
        const req = makeReq({ headers: {} });
        const res = makeRes();
        await stripeWebhook(req, res);
        expect(res.status).toHaveBeenCalledWith(400);
    });
    it("returns 400 when signature verification fails", async () => {
        stripe_1.mockConstructEvent.mockImplementationOnce(() => {
            throw new Error("Invalid signature");
        });
        const req = makeReq();
        const res = makeRes();
        await stripeWebhook(req, res);
        expect(res.status).toHaveBeenCalledWith(400);
    });
    it("grants RC entitlement on customer.subscription.created with status active", async () => {
        const subscription = {
            metadata: { firebaseUID: "user-abc" },
            status: "active",
        };
        stripe_1.mockConstructEvent.mockReturnValueOnce({
            type: "customer.subscription.created",
            data: { object: subscription },
        });
        const req = makeReq();
        const res = makeRes();
        await stripeWebhook(req, res);
        expect(mockFetch).toHaveBeenCalledWith(expect.stringContaining("/v1/subscribers/user-abc/entitlements/premium/promotional"), expect.objectContaining({ method: "POST" }));
        expect(res.json).toHaveBeenCalledWith({ received: true });
    });
    it("grants RC entitlement on subscription.updated with status trialing", async () => {
        const subscription = {
            metadata: { firebaseUID: "user-trialing" },
            status: "trialing",
        };
        stripe_1.mockConstructEvent.mockReturnValueOnce({
            type: "customer.subscription.updated",
            data: { object: subscription },
        });
        const req = makeReq();
        const res = makeRes();
        await stripeWebhook(req, res);
        expect(mockFetch).toHaveBeenCalledWith(expect.stringContaining("/v1/subscribers/user-trialing/entitlements/premium/promotional"), expect.objectContaining({ method: "POST" }));
    });
    it("revokes RC entitlement on customer.subscription.deleted", async () => {
        const subscription = {
            metadata: { firebaseUID: "user-deleted" },
            status: "canceled",
        };
        stripe_1.mockConstructEvent.mockReturnValueOnce({
            type: "customer.subscription.deleted",
            data: { object: subscription },
        });
        const req = makeReq();
        const res = makeRes();
        await stripeWebhook(req, res);
        expect(mockFetch).toHaveBeenCalledWith(expect.stringContaining("/v1/subscribers/user-deleted/entitlements/premium/promotional"), expect.objectContaining({ method: "DELETE" }));
        expect(res.json).toHaveBeenCalledWith({ received: true });
    });
    it("revokes RC entitlement on subscription.updated with status canceled", async () => {
        const subscription = {
            metadata: { firebaseUID: "user-cancel" },
            status: "canceled",
        };
        stripe_1.mockConstructEvent.mockReturnValueOnce({
            type: "customer.subscription.updated",
            data: { object: subscription },
        });
        const req = makeReq();
        const res = makeRes();
        await stripeWebhook(req, res);
        expect(mockFetch).toHaveBeenCalledWith(expect.stringContaining("/v1/subscribers/user-cancel/entitlements/premium/promotional"), expect.objectContaining({ method: "DELETE" }));
    });
    it("skips entitlement action when firebaseUID is missing from metadata", async () => {
        const subscription = {
            metadata: {},
            status: "active",
        };
        stripe_1.mockConstructEvent.mockReturnValueOnce({
            type: "customer.subscription.created",
            data: { object: subscription },
        });
        const req = makeReq();
        const res = makeRes();
        await stripeWebhook(req, res);
        expect(mockFetch).not.toHaveBeenCalled();
        expect(mockDocSet).not.toHaveBeenCalled();
        expect(res.json).toHaveBeenCalledWith({ received: true });
    });
    it("writes premiumEntitlement to Firestore on grant with active:true", async () => {
        const subscription = {
            metadata: { firebaseUID: "user-grant" },
            status: "active",
        };
        stripe_1.mockConstructEvent.mockReturnValueOnce({
            type: "customer.subscription.created",
            data: { object: subscription },
        });
        const req = makeReq();
        const res = makeRes();
        await stripeWebhook(req, res);
        expect(mockDocSet).toHaveBeenCalledWith({ premiumEntitlement: { active: true, expiresAt: null, source: "stripe" } }, { merge: true });
    });
    it("writes premiumEntitlement to Firestore on revoke with active:false", async () => {
        const subscription = {
            metadata: { firebaseUID: "user-revoke" },
            status: "canceled",
        };
        stripe_1.mockConstructEvent.mockReturnValueOnce({
            type: "customer.subscription.deleted",
            data: { object: subscription },
        });
        const req = makeReq();
        const res = makeRes();
        await stripeWebhook(req, res);
        expect(mockDocSet).toHaveBeenCalledWith({
            premiumEntitlement: {
                active: false,
                expiresAt: expect.any(Object),
                source: "stripe",
            },
        }, { merge: true });
    });
});
//# sourceMappingURL=stripeWebhook.test.js.map