// Test stubs for stripeWebhook (BACK-03)

describe('stripeWebhook', () => {
  it('returns 400 when stripe-signature header is missing', async () => {
    expect(true).toBe(false); // RED — implement in 02-02
  });

  it('writes premiumEntitlement.active=true on checkout.session.completed', async () => {
    expect(true).toBe(false); // RED — implement in 02-02
  });

  it('writes premiumEntitlement.active=false on customer.subscription.deleted', async () => {
    expect(true).toBe(false); // RED — implement in 02-02
  });

  it('returns { received: true } for all event types', async () => {
    expect(true).toBe(false); // RED — implement in 02-02
  });
});
