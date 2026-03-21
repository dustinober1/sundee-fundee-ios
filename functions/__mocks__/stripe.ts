// Mock for stripe

const mockStripe = {
  checkout: {
    sessions: {
      create: jest.fn().mockResolvedValue({
        id: 'cs_test_mock',
        url: 'https://checkout.stripe.com/pay/cs_test_mock',
      }),
    },
  },
  customers: {
    create: jest.fn().mockResolvedValue({
      id: 'cus_test_mock',
      email: 'test@example.com',
      metadata: { firebaseUID: 'test-uid' },
    }),
    retrieve: jest.fn().mockResolvedValue({
      id: 'cus_test_mock',
      email: 'test@example.com',
      metadata: { firebaseUID: 'test-uid' },
    }),
    list: jest.fn().mockResolvedValue({ data: [] }),
  },
  webhooks: {
    constructEvent: jest.fn().mockReturnValue({
      type: 'checkout.session.completed',
      data: { object: { customer: 'cus_test_mock' } },
    }),
  },
  billingPortal: {
    sessions: {
      create: jest.fn().mockResolvedValue({
        url: 'https://billing.stripe.com/session/mock',
      }),
    },
  },
};

function Stripe(_key: string) {
  return mockStripe;
}

Stripe.prototype = mockStripe;

export default Stripe;
module.exports = Stripe;
