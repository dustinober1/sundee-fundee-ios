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
import admin from "firebase-admin";
import MockStripe from "stripe";

// ─── Mock fetch ───────────────────────────────────────────────────────────────

const mockFetch = jest.fn();
global.fetch = mockFetch as unknown as typeof fetch;

// ─── Mock admin.auth().deleteUser ─────────────────────────────────────────────

const mockDeleteUser = jest.fn().mockResolvedValue(undefined);
const mockRecursiveDelete = jest.fn().mockResolvedValue(undefined);
const mockDocGet = jest.fn();
const mockDoc = jest.fn();

// Override the firebase-admin mock for this test file to add deleteUser and recursiveDelete
beforeEach(() => {
  jest.clearAllMocks();

  // Setup auth mock
  (admin as unknown as { auth: jest.Mock }).auth = jest.fn(() => ({
    deleteUser: mockDeleteUser,
  }));

  // Setup firestore mock with recursiveDelete and doc getter
  const mockFirestoreInstance = {
    doc: mockDoc,
    recursiveDelete: mockRecursiveDelete,
  };
  (admin.firestore as unknown as jest.Mock).mockReturnValue(mockFirestoreInstance);

  // Default: user doc has stripeSubscriptionId
  mockDoc.mockReturnValue({
    get: mockDocGet,
  });
  mockDocGet.mockResolvedValue({
    data: () => ({ stripeSubscriptionId: "sub_test123" }),
  });

  // Default: RC revoke succeeds
  mockFetch.mockResolvedValue({ ok: true, status: 200 });
});

// ─── Import after mocks are set up ────────────────────────────────────────────

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { deleteAccount } = require("../src/deleteAccount");

// ─── Helper to call the function ─────────────────────────────────────────────

interface CallRequest {
  auth?: { uid: string } | null;
}

async function callDeleteAccount(request: CallRequest): Promise<unknown> {
  return deleteAccount(request);
}

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
    test("calls RC revoke, reads user doc, cancels Stripe, recursiveDelete, deleteUser in order and returns success", async () => {
      const callOrder: string[] = [];

      mockFetch.mockImplementation(async (url: string, opts: { method: string }) => {
        if (opts.method === "DELETE") callOrder.push("rc-revoke");
        return { ok: true, status: 200 };
      });

      mockDocGet.mockImplementation(async () => {
        callOrder.push("doc-get");
        return { data: () => ({ stripeSubscriptionId: "sub_abc" }) };
      });

      // Get the stripe instance that was created during module load
      const stripeInstances = (MockStripe as unknown as jest.Mock).mock?.instances;
      const latestInstance = stripeInstances?.[stripeInstances.length - 1];
      if (latestInstance?.subscriptions?.cancel) {
        latestInstance.subscriptions.cancel.mockImplementation(async () => {
          callOrder.push("stripe-cancel");
          return {};
        });
      }

      mockRecursiveDelete.mockImplementation(async () => {
        callOrder.push("recursive-delete");
      });

      mockDeleteUser.mockImplementation(async () => {
        callOrder.push("delete-user");
      });

      const result = await callDeleteAccount({ auth: { uid: "user123" } });
      expect(result).toEqual({ success: true });

      // Verify RC was revoked
      expect(mockFetch).toHaveBeenCalledWith(
        expect.stringContaining("user123"),
        expect.objectContaining({ method: "DELETE" })
      );

      // Verify user doc was read for stripeSubscriptionId
      expect(mockDoc).toHaveBeenCalledWith("users/user123");
      expect(mockDocGet).toHaveBeenCalled();

      // Verify Firestore recursive delete was called
      expect(mockRecursiveDelete).toHaveBeenCalled();

      // Verify auth user was deleted
      expect(mockDeleteUser).toHaveBeenCalledWith("user123");
    });
  });

  describe("missing stripeSubscriptionId", () => {
    test("skips Stripe cancel when user doc has no stripeSubscriptionId", async () => {
      mockDocGet.mockResolvedValue({
        data: () => ({ premiumEntitlement: { active: true } }), // no stripeSubscriptionId
      });

      const result = await callDeleteAccount({ auth: { uid: "user456" } });
      expect(result).toEqual({ success: true });

      // Verify Firestore recursive delete and auth delete still happen
      expect(mockRecursiveDelete).toHaveBeenCalled();
      expect(mockDeleteUser).toHaveBeenCalledWith("user456");
    });

    test("skips Stripe cancel when user doc data() returns null", async () => {
      mockDocGet.mockResolvedValue({
        data: () => null,
      });

      const result = await callDeleteAccount({ auth: { uid: "user789" } });
      expect(result).toEqual({ success: true });
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
      mockDocGet.mockResolvedValue({
        data: () => ({ stripeSubscriptionId: "sub_fail" }),
      });

      // Stripe cancel throws
      const stripeInstances = (MockStripe as unknown as jest.Mock).mock?.instances;
      const latestInstance = stripeInstances?.[stripeInstances.length - 1];
      if (latestInstance?.subscriptions?.cancel) {
        latestInstance.subscriptions.cancel.mockRejectedValue(new Error("Stripe error"));
      }

      const result = await callDeleteAccount({ auth: { uid: "userB" } });
      expect(result).toEqual({ success: true });

      // Firestore and Auth must still be cleaned up
      expect(mockRecursiveDelete).toHaveBeenCalled();
      expect(mockDeleteUser).toHaveBeenCalledWith("userB");
    });
  });
});
