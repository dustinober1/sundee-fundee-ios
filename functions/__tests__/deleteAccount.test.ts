/**
 * Tests for deleteAccount Cloud Function.
 *
 * Covers:
 * - Unauthenticated request rejection
 * - Full deletion flow: RC revoke → Stripe cancel → Firestore recursiveDelete → Auth deleteUser
 * - Missing stripeSubscriptionId skips Stripe cancel
 * - RC revoke failure does not block deletion
 * - Stripe cancel failure does not block deletion
 */

import { HttpsError } from "firebase-functions/v2/https";

// ─── Mock fetch ───────────────────────────────────────────────────────────────

const mockFetch = jest.fn();
global.fetch = mockFetch as unknown as typeof fetch;

// ─── Module-level jest mocks for admin internals ──────────────────────────────

const mockDeleteUser = jest.fn();
const mockRecursiveDelete = jest.fn();
const mockDocGetFn = jest.fn();
const mockDocFn = jest.fn(() => ({ get: mockDocGetFn, set: jest.fn() }));
const mockSubscriptionsCancel = jest.fn();

// Override firebase-admin mock to inject our per-test mocks
jest.mock("firebase-admin", () => {
  const firestoreInstance = {
    doc: mockDocFn,
    recursiveDelete: mockRecursiveDelete,
  };
  const firestoreFn = jest.fn(() => firestoreInstance);
  (firestoreFn as unknown as { FieldValue: unknown }).FieldValue = {
    serverTimestamp: () => ({ _serverTimestamp: true }),
  };
  (firestoreFn as unknown as { Timestamp: { now: jest.Mock } }).Timestamp = {
    now: jest.fn(() => ({ _seconds: 1234567890, _nanoseconds: 0 })),
  };

  return {
    __esModule: true,
    default: {
      firestore: firestoreFn,
      auth: jest.fn(() => ({ deleteUser: mockDeleteUser })),
      initializeApp: jest.fn(),
    },
    firestore: firestoreFn,
    auth: jest.fn(() => ({ deleteUser: mockDeleteUser })),
  };
});

// Override stripe mock to inject our cancel mock
jest.mock("stripe", () => {
  const MockStripe = jest.fn().mockImplementation(() => ({
    checkout: { sessions: { create: jest.fn() } },
    webhooks: { constructEvent: jest.fn() },
    subscriptions: { cancel: mockSubscriptionsCancel },
  }));
  return { __esModule: true, default: MockStripe };
});

// ─── Import the function under test (after mocks) ────────────────────────────

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { deleteAccount } = require("../src/deleteAccount");

// ─── Helper to call the function ─────────────────────────────────────────────

interface CallRequest {
  auth?: { uid: string } | null;
}

async function callDeleteAccount(request: CallRequest): Promise<unknown> {
  return deleteAccount(request);
}

// ─── Setup ────────────────────────────────────────────────────────────────────

beforeEach(() => {
  jest.clearAllMocks();

  // Default: RC revoke succeeds
  mockFetch.mockResolvedValue({ ok: true, status: 200 });

  // Default: user doc has stripeSubscriptionId
  mockDocGetFn.mockResolvedValue({
    data: () => ({ stripeSubscriptionId: "sub_test123" }),
  });
  mockDocFn.mockReturnValue({ get: mockDocGetFn, set: jest.fn() });

  // Default: Stripe cancel, recursiveDelete, deleteUser succeed
  mockSubscriptionsCancel.mockResolvedValue({ id: "sub_test123", status: "canceled" });
  mockRecursiveDelete.mockResolvedValue(undefined);
  mockDeleteUser.mockResolvedValue(undefined);
});

// ─── Tests ────────────────────────────────────────────────────────────────────

describe("deleteAccount", () => {
  describe("authentication guard", () => {
    test("throws HttpsError with code 'unauthenticated' when request.auth is null", async () => {
      await expect(callDeleteAccount({ auth: null })).rejects.toThrow(HttpsError);
      await expect(callDeleteAccount({ auth: null })).rejects.toMatchObject({
        code: "unauthenticated",
      });
    });

    test("throws HttpsError with code 'unauthenticated' when request.auth is undefined", async () => {
      await expect(callDeleteAccount({})).rejects.toThrow(HttpsError);
    });
  });

  describe("full deletion flow", () => {
    test("calls RC revoke, reads user doc, cancels Stripe, recursiveDelete, deleteUser and returns success", async () => {
      const result = await callDeleteAccount({ auth: { uid: "user123" } });
      expect(result).toEqual({ success: true });

      // Verify RC was revoked (fetch called with DELETE to RC API)
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining("user123"),
        expect.objectContaining({ method: "DELETE" })
      );

      // Verify user doc was read for stripeSubscriptionId
      expect(mockDocFn).toHaveBeenCalledWith("users/user123");
      expect(mockDocGetFn).toHaveBeenCalled();

      // Verify Stripe subscription was cancelled
      expect(mockSubscriptionsCancel).toHaveBeenCalledWith("sub_test123");

      // Verify Firestore recursive delete was called
      expect(mockRecursiveDelete).toHaveBeenCalled();

      // Verify Firebase Auth user was deleted
      expect(mockDeleteUser).toHaveBeenCalledWith("user123");
    });
  });

  describe("missing stripeSubscriptionId", () => {
    test("skips Stripe cancel when user doc has no stripeSubscriptionId", async () => {
      mockDocGetFn.mockResolvedValue({
        data: () => ({ premiumEntitlement: { active: true } }), // no stripeSubscriptionId
      });

      const result = await callDeleteAccount({ auth: { uid: "user456" } });
      expect(result).toEqual({ success: true });

      // Stripe cancel should NOT be called
      expect(mockSubscriptionsCancel).not.toHaveBeenCalled();

      // Firestore and Auth deletion must still happen
      expect(mockRecursiveDelete).toHaveBeenCalled();
      expect(mockDeleteUser).toHaveBeenCalledWith("user456");
    });

    test("skips Stripe cancel when user doc data() returns null", async () => {
      mockDocGetFn.mockResolvedValue({
        data: () => null,
      });

      const result = await callDeleteAccount({ auth: { uid: "user789" } });
      expect(result).toEqual({ success: true });

      expect(mockSubscriptionsCancel).not.toHaveBeenCalled();
      expect(mockRecursiveDelete).toHaveBeenCalled();
      expect(mockDeleteUser).toHaveBeenCalledWith("user789");
    });
  });

  describe("best-effort error handling", () => {
    test("RC revoke failure does not block deletion — still deletes Firestore and Auth", async () => {
      mockFetch.mockRejectedValue(new Error("RC network error"));

      const result = await callDeleteAccount({ auth: { uid: "userA" } });
      expect(result).toEqual({ success: true });

      // Firestore and Auth must still be cleaned up
      expect(mockRecursiveDelete).toHaveBeenCalled();
      expect(mockDeleteUser).toHaveBeenCalledWith("userA");
    });

    test("Stripe cancel failure does not block deletion — still deletes Firestore and Auth", async () => {
      // User has subscription ID
      mockDocGetFn.mockResolvedValue({
        data: () => ({ stripeSubscriptionId: "sub_fail" }),
      });

      // Stripe cancel throws
      mockSubscriptionsCancel.mockRejectedValue(new Error("Stripe error"));

      const result = await callDeleteAccount({ auth: { uid: "userB" } });
      expect(result).toEqual({ success: true });

      // Firestore and Auth must still be cleaned up
      expect(mockRecursiveDelete).toHaveBeenCalled();
      expect(mockDeleteUser).toHaveBeenCalledWith("userB");
    });
  });
});
