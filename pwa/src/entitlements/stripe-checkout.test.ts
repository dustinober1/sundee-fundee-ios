/**
 * Unit tests for stripe-checkout utility.
 * Verifies Cloud Function call params and window.location redirect.
 */
import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock firebase/functions before importing the module under test
vi.mock('firebase/functions', () => ({
  getFunctions: vi.fn(() => ({})),
  httpsCallable: vi.fn(),
}));

// Mock firebase/app module
vi.mock('../firebase/app', () => ({
  getFirebaseApp: vi.fn(() => ({})),
}));

import { getFunctions, httpsCallable } from 'firebase/functions';
import { redirectToCheckout, STRIPE_PREMIUM_PRICE_ID } from './stripe-checkout';

const mockCallable = vi.fn();

beforeEach(() => {
  vi.clearAllMocks();
  (httpsCallable as ReturnType<typeof vi.fn>).mockReturnValue(mockCallable);
  mockCallable.mockResolvedValue({
    data: { url: 'https://checkout.stripe.com/test-session' },
  });

  // Patch window.location.href (jsdom allows assignment)
  Object.defineProperty(window, 'location', {
    writable: true,
    value: { href: '', origin: 'https://example.com' },
  });
});

describe('redirectToCheckout', () => {
  it('calls httpsCallable with createStripeCheckoutSession function name', async () => {
    const functionsInstance = {};
    (getFunctions as ReturnType<typeof vi.fn>).mockReturnValue(functionsInstance);

    await redirectToCheckout('uid-123', 'price_xxx');

    expect(httpsCallable).toHaveBeenCalledWith(
      functionsInstance,
      'createStripeCheckoutSession',
    );
  });

  it('passes correct uid, priceId, successUrl, and cancelUrl to callable', async () => {
    await redirectToCheckout('uid-123', 'price_xxx');

    expect(mockCallable).toHaveBeenCalledWith(
      expect.objectContaining({
        uid: 'uid-123',
        priceId: 'price_xxx',
        successUrl: expect.stringContaining('/settings?checkout=success'),
        cancelUrl: expect.stringContaining('/settings?checkout=cancelled'),
      }),
    );
  });

  it('sets window.location.href to the URL returned by the Cloud Function', async () => {
    await redirectToCheckout('uid-123', 'price_xxx');

    expect(window.location.href).toBe('https://checkout.stripe.com/test-session');
  });
});

describe('STRIPE_PREMIUM_PRICE_ID', () => {
  it('exports a non-empty string', () => {
    expect(typeof STRIPE_PREMIUM_PRICE_ID).toBe('string');
    expect(STRIPE_PREMIUM_PRICE_ID.length).toBeGreaterThan(0);
  });
});
