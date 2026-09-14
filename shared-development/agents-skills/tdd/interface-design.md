# Interface Design for Testability

Good interfaces make testing natural:

1. **Accept dependencies, don't create them**

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **Return results, don't produce side effects**

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **Small surface area**
   - Fewer methods = fewer tests needed
   - Fewer params = simpler test setup

4. **Make failures part of the contract**
   - Expose stable error types or codes where callers need to branch
   - Distinguish terminal failures from retryable failures
   - Avoid leaking provider errors, secrets, or stack traces directly

5. **Make critical invariants observable**
   - Provide a public read path for durable outcomes where appropriate
   - Accept idempotency keys or operation identifiers when safe retry is required
   - Define cancellation, timeout, rollback, and partial-success semantics
