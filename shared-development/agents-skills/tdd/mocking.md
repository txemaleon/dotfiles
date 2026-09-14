# When to Mock

Use test doubles at **system boundaries** only:

- External APIs (payment, email, etc.)
- Databases only when a real test database is impractical
- Time/randomness
- File system (sometimes)

Don't mock:

- Your own classes/modules
- Internal collaborators
- Anything you control

For critical-path integration tests, run real application components and real test persistence where feasible. A graph of mocked internal collaborators is not an integration test.

## Inject Failures Deliberately

Make boundary doubles support deterministic outcomes that the production boundary can actually produce:

- domain refusal, such as a declined payment;
- timeout, cancellation, or connection failure;
- unavailable service or rate limit;
- malformed or incomplete response;
- a sequence such as transient failure followed by success.

Keep these modes explicit in the fixture API. Do not hide conditional behavior in a generic mock that is difficult to read or can accidentally return success.

Verify each fake or stub against the real boundary contract when practical. Prefer a local test server or provider sandbox when serialization, status mapping, authentication, or protocol behavior is part of the risk.

Assert boundary interactions only when the interaction is itself contractual, such as idempotency, an irreversible external effect, or a documented retry limit. Avoid arbitrary call-count assertions about internal implementation.

## Designing for Mockability

At system boundaries, design interfaces that are easy to mock:

**1. Use dependency injection**

Pass external dependencies in rather than creating them internally:

```typescript
// Easy to mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// Hard to mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. Prefer SDK-style interfaces over generic fetchers**

Create specific functions for each external operation instead of one generic function with conditional logic:

```typescript
// GOOD: Each function is independently mockable
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// BAD: Mocking requires conditional logic inside the mock
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

The SDK approach means:
- Each mock returns one specific shape
- No conditional logic in test setup
- Easier to see which endpoints a test exercises
- Type safety per endpoint
