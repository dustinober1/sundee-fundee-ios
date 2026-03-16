"use strict";
/**
 * Tests for createCheckoutSession Cloud Function.
 *
 * Uses jest.mock("stripe") to ensure the same mock instance is used
 * both in the test and inside the module under test.
 */
// ─── Mock Stripe ──────────────────────────────────────────────────────────────
const mockSessionCreate = jest.fn().mockResolvedValue({
    id: "cs_test_mock",
    url: "https://checkout.stripe.com/pay/cs_test_mock",
});
jest.mock("stripe", () => {
    const MockStripe = jest.fn().mockImplementation(() => ({
        checkout: {
            sessions: {
                create: mockSessionCreate,
            },
        },
        webhooks: {
            constructEvent: jest.fn(),
        },
    }));
    return { __esModule: true, default: MockStripe };
});
// ─── Import the module under test (after mocks) ───────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-require-imports
const { createCheckoutSession } = require("../createCheckoutSession");
// ─── Setup ────────────────────────────────────────────────────────────────────
beforeEach(() => {
    jest.clearAllMocks();
    mockSessionCreate.mockResolvedValue({
        id: "cs_test_mock",
        url: "https://checkout.stripe.com/pay/cs_test_mock",
    });
});
// ─── Tests ────────────────────────────────────────────────────────────────────
describe("createCheckoutSession", () => {
    it("rejects unauthenticated requests with HttpsError unauthenticated", async () => {
        const request = { auth: null, data: {} };
        await expect(createCheckoutSession(request)).rejects.toMatchObject({
            code: "unauthenticated",
        });
    });
    it("creates a Stripe Checkout session with correct params and returns url", async () => {
        const request = {
            auth: { uid: "user-123" },
            data: {
                priceId: "price_monthly",
                successUrl: "https://app.example.com/success",
                cancelUrl: "https://app.example.com/cancel",
            },
        };
        const result = await createCheckoutSession(request);
        expect(mockSessionCreate).toHaveBeenCalledWith(expect.objectContaining({
            mode: "subscription",
            line_items: [{ price: "price_monthly", quantity: 1 }],
            success_url: "https://app.example.com/success",
            cancel_url: "https://app.example.com/cancel",
            payment_method_collection: "if_required",
        }));
        expect(result).toEqual({ url: "https://checkout.stripe.com/pay/cs_test_mock" });
    });
    it("includes firebaseUID in subscription_data.metadata", async () => {
        const request = {
            auth: { uid: "firebase-uid-456" },
            data: {
                priceId: "price_annual",
                successUrl: "https://app.example.com/success",
                cancelUrl: "https://app.example.com/cancel",
            },
        };
        await createCheckoutSession(request);
        expect(mockSessionCreate).toHaveBeenCalledWith(expect.objectContaining({
            subscription_data: expect.objectContaining({
                metadata: expect.objectContaining({ firebaseUID: "firebase-uid-456" }),
            }),
        }));
    });
    it("includes 7-day trial_period_days in subscription_data", async () => {
        const request = {
            auth: { uid: "user-trial" },
            data: {
                priceId: "price_monthly",
                successUrl: "https://app.example.com/success",
                cancelUrl: "https://app.example.com/cancel",
            },
        };
        await createCheckoutSession(request);
        expect(mockSessionCreate).toHaveBeenCalledWith(expect.objectContaining({
            subscription_data: expect.objectContaining({
                trial_period_days: 7,
            }),
        }));
    });
});
//# sourceMappingURL=createCheckoutSession.test.js.map