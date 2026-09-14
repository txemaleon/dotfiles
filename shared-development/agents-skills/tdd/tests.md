# Test Design

## Test Through Observable Behavior

Prefer tests that enter through a public API and verify results through public read interfaces. Such tests survive internal refactors and read as specifications.

Use multiple assertions when they jointly prove one outcome. “One behavior per test” is more useful than “one assertion per test,” especially when an error contract and a state invariant must be verified together.

```typescript
test("checkout confirms an order when payment is approved", async () => {
  const app = await createTestApp({ payment: paymentStub.approved() });

  const result = await app.checkout(validCart(), validPayment());
  const order = await app.getOrder(result.orderId);

  expect(result.status).toBe("confirmed");
  expect(order.status).toBe("confirmed");
});
```

This is integration-style when `app.checkout` uses the real application flow, domain logic, and test persistence. The payment stub replaces a true external boundary, not an internal module.

## Avoid Tautological Tests

An assertion is tautological when it recomputes the expected value with the same rule as the production code. It passes by construction and cannot reveal that the shared rule is wrong.

```typescript
// BAD: the assertion repeats the formula under test
expect(calculateTax(100, 0.2)).toBe(100 * 0.2);

// GOOD: the expected result comes from a worked example in the specification
expect(calculateTax(100, 0.2)).toBe(20);
```

Use known-good literals, specification examples, independently produced fixtures, or a trusted reference implementation as the source of expected values. Do not generate a snapshot from the implementation under test and approve it without independently checking the behavior it records.

## Cover the Failure Contract

Pair a critical success test with representative failures that protect different behavior.

```typescript
test("checkout rejects a declined payment without confirming the order", async () => {
  const app = await createTestApp({ payment: paymentStub.declined() });

  await expect(
    app.checkout(validCart(), validPayment()),
  ).rejects.toMatchObject({ code: "PAYMENT_DECLINED", retryable: false });

  const orders = await app.listOrdersForCurrentUser();
  expect(orders).toHaveLength(0);
});
```

```typescript
test("checkout can be retried safely after a payment timeout", async () => {
  const app = await createTestApp({
    payment: paymentStub.sequence(["timeout", "approved"]),
  });
  const request = checkoutRequest({ idempotencyKey: "checkout-123" });

  await expect(app.checkout(request)).rejects.toMatchObject({
    code: "PAYMENT_UNAVAILABLE",
    retryable: true,
  });

  const result = await app.checkout(request);
  const orders = await app.listOrdersForCurrentUser();

  expect(result.status).toBe("confirmed");
  expect(orders).toHaveLength(1);
});
```

Adapt the examples to the system's real contract. Do not invent retryability, persistence, or idempotency requirements solely for a test.

## Select Negative Cases by Risk

Consider these behavior classes for each critical path:

- malformed, missing, unauthorized, or conflicting input;
- expected domain rejection;
- dependency refusal, timeout, unavailability, or malformed response;
- persistence failure or concurrent update;
- cancellation, retry, duplicate request, or partial completion;
- recovery after a transient failure.

Choose cases that exercise distinct public behavior or invariants. Avoid exhaustive permutations that all traverse the same branch.

## Use the Right Scope

- **Integration:** Prove a critical path across the public entry point, real internal components, and real test persistence where feasible.
- **Unit:** Prove pure calculations, dense branching, and boundary values cheaply.
- **End-to-end:** Prove a small amount of environment, deployment, and third-party wiring that lower levels cannot.

If direct state inspection is required to prove a non-public invariant, use the narrowest stable test seam and explain why the public interface is insufficient. Do not couple the test to incidental table layout or private method structure.

## Avoid Implementation Tests

```typescript
// BAD: verifies internal collaboration instead of behavior
test("checkout calls paymentService.process", async () => {
  const payment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(payment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- mocking internal collaborators;
- testing private methods;
- asserting arbitrary call counts or ordering;
- checking only that an error was thrown;
- checking only an error message while ignoring state and side effects;
- recomputing expected values with the same formula, parser, transformation, or constants as the production code;
- passing after a critical internal component has been bypassed;
- breaking on a refactor that preserves supported behavior.
