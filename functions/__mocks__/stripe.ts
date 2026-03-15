const mockSessionCreate = jest.fn().mockResolvedValue({
  id: "cs_test_mock",
  url: "https://checkout.stripe.com/pay/cs_test_mock",
});

const mockConstructEvent = jest.fn();

const mockSubscriptionsCancel = jest.fn().mockResolvedValue({ id: "sub_mock", status: "canceled" });

const MockStripe = jest.fn().mockImplementation(() => ({
  checkout: {
    sessions: {
      create: mockSessionCreate,
    },
  },
  webhooks: {
    constructEvent: mockConstructEvent,
  },
  subscriptions: {
    cancel: mockSubscriptionsCancel,
  },
}));

export default MockStripe;
export { mockSessionCreate, mockConstructEvent, mockSubscriptionsCancel };
