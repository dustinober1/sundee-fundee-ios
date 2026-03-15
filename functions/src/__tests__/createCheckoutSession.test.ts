import { mockSessionCreate } from "../../__mocks__/stripe";

// The mock wraps onCall so the handler is directly callable
const { createCheckoutSession } = require("../createCheckoutSession");

describe("createCheckoutSession", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

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

    expect(mockSessionCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        mode: "subscription",
        line_items: [{ price: "price_monthly", quantity: 1 }],
        success_url: "https://app.example.com/success",
        cancel_url: "https://app.example.com/cancel",
        payment_method_collection: "if_required",
      })
    );
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

    expect(mockSessionCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        subscription_data: expect.objectContaining({
          metadata: expect.objectContaining({ firebaseUID: "firebase-uid-456" }),
        }),
      })
    );
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

    expect(mockSessionCreate).toHaveBeenCalledWith(
      expect.objectContaining({
        subscription_data: expect.objectContaining({
          trial_period_days: 7,
        }),
      })
    );
  });
});
