const mockSessionCreate = jest.fn().mockResolvedValue({
  id: "cs_test_mock",
  url: "https://checkout.stripe.com/pay/cs_test_mock",
});

const mockConstructEvent = jest.fn();

const MockStripe = jest.fn().mockImplementation(() => ({
  checkout: {
    sessions: {
      create: mockSessionCreate,
    },
  },
  webhooks: {
    constructEvent: mockConstructEvent,
  },
}));

export default MockStripe;
export { mockSessionCreate, mockConstructEvent };
