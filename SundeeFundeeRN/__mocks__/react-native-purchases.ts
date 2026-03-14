/**
 * Mock for react-native-purchases (RevenueCat)
 *
 * Provides Jest function stubs for RevenueCat SDK operations.
 * Simulates a non-premium user by default (no active entitlements).
 *
 * To simulate a premium user in tests, override getCustomerInfo:
 * ```typescript
 * import Purchases from 'react-native-purchases';
 * jest.mocked(Purchases.getCustomerInfo).mockResolvedValueOnce({
 *   entitlements: { active: { premium: { identifier: 'premium' } } },
 * } as any);
 * ```
 */

const mockCustomerInfo = {
  originalAppUserId: 'mock-rc-user-id',
  entitlements: {
    active: {}, // No active entitlements by default
    all: {},
  },
  activeSubscriptions: [],
  allPurchasedProductIdentifiers: [],
  latestExpirationDate: null,
  firstSeen: new Date().toISOString(),
};

const Purchases = {
  configure: jest.fn(),
  getCustomerInfo: jest.fn().mockResolvedValue(mockCustomerInfo),
  identify: jest.fn().mockResolvedValue(mockCustomerInfo),
  logIn: jest.fn().mockResolvedValue({ customerInfo: mockCustomerInfo, created: false }),
  logOut: jest.fn().mockResolvedValue(mockCustomerInfo),
  setAttributes: jest.fn().mockResolvedValue(undefined),
  purchaseProduct: jest.fn().mockResolvedValue({ customerInfo: mockCustomerInfo }),
  restorePurchases: jest.fn().mockResolvedValue(mockCustomerInfo),
  isConfigured: jest.fn().mockReturnValue(true),
};

export default Purchases;
