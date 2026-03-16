"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.mockConstructEvent = exports.mockSessionCreate = void 0;
const mockSessionCreate = jest.fn().mockResolvedValue({
    id: "cs_test_mock",
    url: "https://checkout.stripe.com/pay/cs_test_mock",
});
exports.mockSessionCreate = mockSessionCreate;
const mockConstructEvent = jest.fn();
exports.mockConstructEvent = mockConstructEvent;
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
exports.default = MockStripe;
//# sourceMappingURL=stripe.js.map