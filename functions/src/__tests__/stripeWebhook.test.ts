/**
 * Tests for stripeWebhook (BACK-03)
 *
 * The jest moduleNameMapper routes:
 *   firebase-functions/v2/https  → __mocks__/firebase-functions.ts  (provides onRequest)
 *   firebase-admin/firestore     → __mocks__/firebase-admin-firestore.ts
 *   stripe                       → __mocks__/stripe.ts
 */

// IMPORTANT: require via mapped name so we share the same Jest module instance as the implementation
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
  webhooks: { constructEvent: jest.Mock };
  customers: { retrieve: jest.Mock };
};

// Import the module under test
import { stripeWebhook } from '../stripeWebhook';

// ---- Mock request/response helpers ----

type MockResponse = {
  status: jest.Mock;
  json: jest.Mock;
  send: jest.Mock;
  _statusCode: number;
  _body: unknown;
};

function makeRes(): MockResponse {
  const res: MockResponse = {
    _statusCode: 200,
    _body: undefined,
    status: jest.fn().mockImplementation((code: number) => {
      res._statusCode = code;
      return res;
    }),
    json: jest.fn().mockImplementation((body: unknown) => {
      res._body = body;
      return res;
    }),
    send: jest.fn().mockImplementation((body: unknown) => {
      res._body = body;
      return res;
    }),
  };
  return res;
}

function makeReq(opts: {
  headers?: Record<string, string>;
  rawBody?: Buffer | string;
  method?: string;
}): unknown {
  return {
    method: opts.method ?? 'POST',
    headers: opts.headers ?? {},
    rawBody: opts.rawBody ?? Buffer.from('{}'),
    body: {},
  };
}

type WebhookFn = (req: unknown, res: MockResponse) => Promise<void>;

// ---- stripeWebhook tests ----

describe('stripeWebhook', () => {
  beforeEach(() => {
    fsm.resetFirestoreMocks();
    fsm.setMockGetResult({
      exists: true,
      data: () => ({ premiumEntitlement: { stripeCustomerId: 'cus_test_mock' } }),
    });
    // Default Stripe mock behavior
    mockStripeInstance.webhooks.constructEvent.mockReturnValue({
      type: 'checkout.session.completed',
      data: {
        object: { customer: 'cus_test_mock', subscription: 'sub_test_mock' },
      },
    });
    mockStripeInstance.customers.retrieve.mockResolvedValue({
      id: 'cus_test_mock',
      metadata: { firebaseUID: 'user-abc' },
    });
  });

  it('returns 400 when stripe-signature header is missing', async () => {
    const req = makeReq({ headers: {} });
    const res = makeRes();
    await (stripeWebhook as unknown as WebhookFn)(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
  });

  it('writes premiumEntitlement.active=true on checkout.session.completed', async () => {
    mockStripeInstance.webhooks.constructEvent.mockReturnValue({
      type: 'checkout.session.completed',
      data: {
        object: { customer: 'cus_test_mock', subscription: 'sub_test_mock' },
      },
    });
    mockStripeInstance.customers.retrieve.mockResolvedValue({
      id: 'cus_test_mock',
      metadata: { firebaseUID: 'user-abc' },
    });

    const req = makeReq({ headers: { 'stripe-signature': 'sig_test' } });
    const res = makeRes();
    await (stripeWebhook as unknown as WebhookFn)(req, res);

    const handlers = fsm.getHandlers();
    expect(handlers.set).toHaveBeenCalledWith(
      expect.objectContaining({
        premiumEntitlement: expect.objectContaining({ active: true }),
      }),
      { merge: true }
    );
  });

  it('writes premiumEntitlement.active=false on customer.subscription.deleted', async () => {
    mockStripeInstance.webhooks.constructEvent.mockReturnValue({
      type: 'customer.subscription.deleted',
      data: {
        object: { customer: 'cus_test_mock' },
      },
    });
    mockStripeInstance.customers.retrieve.mockResolvedValue({
      id: 'cus_test_mock',
      metadata: { firebaseUID: 'user-abc' },
    });

    const req = makeReq({ headers: { 'stripe-signature': 'sig_test' } });
    const res = makeRes();
    await (stripeWebhook as unknown as WebhookFn)(req, res);

    const handlers = fsm.getHandlers();
    expect(handlers.set).toHaveBeenCalledWith(
      expect.objectContaining({
        premiumEntitlement: expect.objectContaining({ active: false }),
      }),
      { merge: true }
    );
  });

  it('returns { received: true } for all event types', async () => {
    mockStripeInstance.webhooks.constructEvent.mockReturnValue({
      type: 'checkout.session.completed',
      data: {
        object: { customer: 'cus_test_mock', subscription: 'sub_test_mock' },
      },
    });
    mockStripeInstance.customers.retrieve.mockResolvedValue({
      id: 'cus_test_mock',
      metadata: { firebaseUID: 'user-abc' },
    });

    const req = makeReq({ headers: { 'stripe-signature': 'sig_test' } });
    const res = makeRes();
    await (stripeWebhook as unknown as WebhookFn)(req, res);
    expect(res.json).toHaveBeenCalledWith({ received: true });
  });
});
