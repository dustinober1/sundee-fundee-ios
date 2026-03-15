import { mockConstructEvent } from "../../__mocks__/stripe";
import adminMock from "../../__mocks__/firebase-admin";

// We need a mutable reference to the set mock so we can verify calls
let mockDocSet: jest.Mock;

beforeEach(() => {
  jest.clearAllMocks();

  // Re-build the firestore mock so we can capture doc().set calls
  mockDocSet = jest.fn().mockResolvedValue(undefined);
  const mockDoc = jest.fn(() => ({ set: mockDocSet }));
  const mockFirestoreInstance = {
    collection: jest.fn(() => ({ doc: jest.fn(() => ({ id: "mock-id" })) })),
    doc: mockDoc,
  };
  (adminMock.firestore as jest.Mock).mockReturnValue(mockFirestoreInstance);
  (adminMock.firestore as unknown as { Timestamp: { now: jest.Mock } }).Timestamp = {
    now: jest.fn(() => ({ _seconds: 1234567890, _nanoseconds: 0 })),
  };
});

// Stub global fetch for RC API calls
const mockFetch = jest.spyOn(global, "fetch").mockImplementation(
  jest.fn().mockResolvedValue({ ok: true, status: 200 } as Response)
);

// stripeWebhook is an onRequest handler — the mock returns it directly
const { stripeWebhook } = require("../stripeWebhook");

function makeReq(overrides: Partial<{
  headers: Record<string, string | undefined>;
  rawBody: Buffer;
}> = {}) {
  const defaultHeaders: Record<string, string | undefined> = { "stripe-signature": "valid-sig" };
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
    mockConstructEvent.mockImplementationOnce(() => {
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
    mockConstructEvent.mockReturnValueOnce({
      type: "customer.subscription.created",
      data: { object: subscription },
    });

    const req = makeReq();
    const res = makeRes();
    await stripeWebhook(req, res);

    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining("/v1/subscribers/user-abc/entitlements/premium/promotional"),
      expect.objectContaining({ method: "POST" })
    );
    expect(res.json).toHaveBeenCalledWith({ received: true });
  });

  it("grants RC entitlement on subscription.updated with status trialing", async () => {
    const subscription = {
      metadata: { firebaseUID: "user-trialing" },
      status: "trialing",
    };
    mockConstructEvent.mockReturnValueOnce({
      type: "customer.subscription.updated",
      data: { object: subscription },
    });

    const req = makeReq();
    const res = makeRes();
    await stripeWebhook(req, res);

    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining("/v1/subscribers/user-trialing/entitlements/premium/promotional"),
      expect.objectContaining({ method: "POST" })
    );
  });

  it("revokes RC entitlement on customer.subscription.deleted", async () => {
    const subscription = {
      metadata: { firebaseUID: "user-deleted" },
      status: "canceled",
    };
    mockConstructEvent.mockReturnValueOnce({
      type: "customer.subscription.deleted",
      data: { object: subscription },
    });

    const req = makeReq();
    const res = makeRes();
    await stripeWebhook(req, res);

    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining("/v1/subscribers/user-deleted/entitlements/premium/promotional"),
      expect.objectContaining({ method: "DELETE" })
    );
    expect(res.json).toHaveBeenCalledWith({ received: true });
  });

  it("revokes RC entitlement on subscription.updated with status canceled", async () => {
    const subscription = {
      metadata: { firebaseUID: "user-cancel" },
      status: "canceled",
    };
    mockConstructEvent.mockReturnValueOnce({
      type: "customer.subscription.updated",
      data: { object: subscription },
    });

    const req = makeReq();
    const res = makeRes();
    await stripeWebhook(req, res);

    expect(mockFetch).toHaveBeenCalledWith(
      expect.stringContaining("/v1/subscribers/user-cancel/entitlements/premium/promotional"),
      expect.objectContaining({ method: "DELETE" })
    );
  });

  it("skips entitlement action when firebaseUID is missing from metadata", async () => {
    const subscription = {
      metadata: {},
      status: "active",
    };
    mockConstructEvent.mockReturnValueOnce({
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
    mockConstructEvent.mockReturnValueOnce({
      type: "customer.subscription.created",
      data: { object: subscription },
    });

    const req = makeReq();
    const res = makeRes();
    await stripeWebhook(req, res);

    expect(mockDocSet).toHaveBeenCalledWith(
      { premiumEntitlement: { active: true, expiresAt: null, source: "stripe" } },
      { merge: true }
    );
  });

  it("writes premiumEntitlement to Firestore on revoke with active:false", async () => {
    const subscription = {
      metadata: { firebaseUID: "user-revoke" },
      status: "canceled",
    };
    mockConstructEvent.mockReturnValueOnce({
      type: "customer.subscription.deleted",
      data: { object: subscription },
    });

    const req = makeReq();
    const res = makeRes();
    await stripeWebhook(req, res);

    expect(mockDocSet).toHaveBeenCalledWith(
      {
        premiumEntitlement: {
          active: false,
          expiresAt: expect.any(Object),
          source: "stripe",
        },
      },
      { merge: true }
    );
  });
});
