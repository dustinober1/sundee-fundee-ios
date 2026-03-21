/**
 * Tests for createStripeCheckoutSession + createStripePortalSession (BACK-02)
 *
 * The jest moduleNameMapper routes:
 *   firebase-functions/v2/https  → __mocks__/firebase-admin-firestore.ts
 *   firebase-admin/firestore     → __mocks__/firebase-admin-firestore.ts
 *   stripe                       → __mocks__/stripe.ts
 *
 * IMPORTANT: We require 'firebase-admin/firestore' (not a relative path) so that
 * Jest resolves it through the moduleNameMapper, sharing the same module instance
 * as the implementation under test.
 *
 * onCall in the mock returns an async wrapper so exported functions are directly callable.
 */

// eslint-disable-next-line @typescript-eslint/no-require-imports
const fsm = require('firebase-admin/firestore') as {
  setMockGetResult: (r: { exists: boolean; data: () => unknown }) => void;
  resetFirestoreMocks: () => void;
  getHandlers: () => { get: jest.Mock; set: jest.Mock; update: jest.Mock };
};

// Access Stripe mock
// eslint-disable-next-line @typescript-eslint/no-require-imports
const StripeCtor = require('../../__mocks__/stripe');
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const mockStripeInstance = (StripeCtor as any)('mock-key') as {
  customers: { create: jest.Mock; retrieve: jest.Mock };
  checkout: { sessions: { create: jest.Mock } };
  billingPortal: { sessions: { create: jest.Mock } };
};

// Import the module under test
import {
  createStripeCheckoutSession,
  createStripePortalSession,
} from '../createCheckoutSession';

type CallableRequest = {
  auth: { uid: string; token?: Record<string, unknown> } | null;
  data: Record<string, unknown>;
};

function makeRequest(opts: {
  auth?: { uid: string; token?: Record<string, unknown> } | null;
  data?: Record<string, unknown>;
}): CallableRequest {
  return {
    auth: opts.auth ?? null,
    data: opts.data ?? {},
  };
}

const validCheckoutData = {
  priceId: 'price_test_123',
  successUrl: 'https://example.com/success',
  cancelUrl: 'https://example.com/cancel',
};

const validPortalData = {
  returnUrl: 'https://example.com/settings',
};

// ---- createStripeCheckoutSession ----

describe('createStripeCheckoutSession', () => {
  beforeEach(() => {
    fsm.resetFirestoreMocks();
    // Default: user has no existing stripeCustomerId
    fsm.setMockGetResult({ exists: false, data: () => undefined });
    // Restore Stripe mock defaults
    mockStripeInstance.customers.create.mockResolvedValue({
      id: 'cus_test_mock',
      email: 'user@example.com',
      metadata: { firebaseUID: 'user-abc' },
    });
    mockStripeInstance.customers.retrieve.mockResolvedValue({
      id: 'cus_test_mock',
      email: 'user@example.com',
      metadata: { firebaseUID: 'user-abc' },
    });
    mockStripeInstance.checkout.sessions.create.mockResolvedValue({
      id: 'cs_test_mock',
      url: 'https://checkout.stripe.com/pay/cs_test_mock',
    });
  });

  it('rejects unauthenticated calls with HttpsError unauthenticated', async () => {
    const request = makeRequest({ auth: null, data: validCheckoutData });
    const fn = createStripeCheckoutSession as unknown as (r: CallableRequest) => Promise<unknown>;
    await expect(fn(request)).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('returns a URL from Stripe Checkout session', async () => {
    const request = makeRequest({
      auth: { uid: 'user-abc', token: { email: 'user@example.com' } },
      data: validCheckoutData,
    });
    const fn = createStripeCheckoutSession as unknown as (r: CallableRequest) => Promise<{ url: string }>;
    const result = await fn(request);
    expect(result).toHaveProperty('url');
    expect(typeof result.url).toBe('string');
    expect(result.url).toContain('stripe.com');
  });

  it('creates Stripe customer with firebaseUID metadata', async () => {
    const request = makeRequest({
      auth: { uid: 'user-abc', token: { email: 'user@example.com' } },
      data: validCheckoutData,
    });
    const fn = createStripeCheckoutSession as unknown as (r: CallableRequest) => Promise<unknown>;
    await fn(request);
    expect(mockStripeInstance.customers.create).toHaveBeenCalledWith(
      expect.objectContaining({
        metadata: expect.objectContaining({ firebaseUID: 'user-abc' }),
      })
    );
  });
});

// ---- createStripePortalSession ----

describe('createStripePortalSession', () => {
  beforeEach(() => {
    fsm.resetFirestoreMocks();
    // User has existing stripeCustomerId
    fsm.setMockGetResult({
      exists: true,
      data: () => ({
        premiumEntitlement: { active: true, stripeCustomerId: 'cus_test_mock' },
      }),
    });
    // Restore Stripe mock defaults
    mockStripeInstance.billingPortal.sessions.create.mockResolvedValue({
      url: 'https://billing.stripe.com/session/mock',
    });
  });

  it('rejects unauthenticated calls with HttpsError unauthenticated', async () => {
    const request = makeRequest({ auth: null, data: validPortalData });
    const fn = createStripePortalSession as unknown as (r: CallableRequest) => Promise<unknown>;
    await expect(fn(request)).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('returns a URL from Stripe Billing Portal session', async () => {
    const request = makeRequest({
      auth: { uid: 'user-abc' },
      data: validPortalData,
    });
    const fn = createStripePortalSession as unknown as (r: CallableRequest) => Promise<{ url: string }>;
    const result = await fn(request);
    expect(result).toHaveProperty('url');
    expect(typeof result.url).toBe('string');
    expect(result.url).toContain('billing.stripe.com');
  });
});
