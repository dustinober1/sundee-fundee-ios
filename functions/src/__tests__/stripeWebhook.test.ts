/**
 * Tests for stripeWebhook Cloud Function.
 *
 * Uses jest.mock("stripe") and jest.mock("firebase-admin") to ensure
 * the same mock instances are used both in the test and inside the module under test.
 */

// ─── Mock fetch ───────────────────────────────────────────────────────────────

const mockFetch = jest.fn().mockResolvedValue({ ok: true, status: 200 });
global.fetch = mockFetch as unknown as typeof fetch;

// ─── Mock Stripe ──────────────────────────────────────────────────────────────

const mockConstructEvent = jest.fn();
const mockCheckoutSessionsCreate = jest.fn();

jest.mock("stripe", () => {
  const MockStripe = jest.fn().mockImplementation(() => ({
    checkout: {
      sessions: {
        create: mockCheckoutSessionsCreate,
      },
    },
    webhooks: {
      constructEvent: mockConstructEvent,
    },
  }));
  return { __esModule: true, default: MockStripe };
});

// ─── Mock firebase-admin ──────────────────────────────────────────────────────

const mockDocSet = jest.fn().mockResolvedValue(undefined);
const mockDoc = jest.fn(() => ({ set: mockDocSet }));
const mockFirestoreInstance = {
  collection: jest.fn(() => ({ doc: jest.fn(() => ({ id: "mock-id" })) })),
  doc: mockDoc,
};

const mockFirestore = jest.fn(() => mockFirestoreInstance);
(mockFirestore as unknown as { Timestamp: { now: jest.Mock } }).Timestamp = {
  now: jest.fn(() => ({ _seconds: 1234567890, _nanoseconds: 0 })),
};

jest.mock("firebase-admin", () => ({
  __esModule: true,
  default: {
    firestore: mockFirestore,
    auth: jest.fn(() => ({ deleteUser: jest.fn() })),
    initializeApp: jest.fn(),
  },
  firestore: mockFirestore,
  auth: jest.fn(() => ({ deleteUser: jest.fn() })),
}));

// ─── Import the module under test (after mocks) ───────────────────────────────

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { stripeWebhook } = require("../stripeWebhook");

// ─── Setup ────────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();
  mockFetch.mockResolvedValue({ ok: true, status: 200 });
  mockDocSet.mockResolvedValue(undefined);
  mockDoc.mockReturnValue({ set: mockDocSet });
  mockFirestore.mockReturnValue(mockFirestoreInstance);
  (mockFirestore as unknown as { Timestamp: { now: jest.Mock } }).Timestamp = {
    now: jest.fn(() => ({ _seconds: 1234567890, _nanoseconds: 0 })),
  };
});

// ─── Helpers ──────────────────────────────────────────────────────────────────

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
  return {
    status: jest.fn().mockReturnThis(),
    send: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  };
}

// ─── Tests ────────────────────────────────────────────────────────────────────

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
      id: "sub_abc",
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
      id: "sub_trialing",
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
      id: "sub_deleted",
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
      id: "sub_cancel",
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
      id: "sub_no_uid",
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

  it("writes premiumEntitlement and stripeSubscriptionId to Firestore on grant", async () => {
    const subscription = {
      id: "sub_grant",
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
      {
        premiumEntitlement: { active: true, expiresAt: null, source: "stripe" },
        stripeSubscriptionId: "sub_grant",
      },
      { merge: true }
    );
  });

  it("writes premiumEntitlement to Firestore on revoke with active:false", async () => {
    const subscription = {
      id: "sub_revoke",
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
