# Testing TypeScript

Apply these practices after inspecting `package.json`, the lockfile, `tsconfig` files, test configuration, and representative existing tests. Preserve the project's runner and conventions unless the user explicitly asks for a migration.

## Contents

- [Toolchain and type safety](#toolchain-and-type-safety)
- [Unit tests](#unit-tests)
- [Integration tests](#integration-tests)
- [UI tests](#ui-tests)
- [Async code and time](#async-code-and-time)
- [Fixtures, isolation, and mocks](#fixtures-isolation-and-mocks)
- [Execution and CI](#execution-and-ci)
- [Official sources](#official-sources)

## Toolchain and Type Safety

- Run runtime tests and TypeScript checking as separate quality signals. A runner may transpile `.ts` files without type-checking them; Vitest does this by default, as does Jest when configured through Babel.
- Ensure the test files and test utilities are included in a `tsc --noEmit`, project build, or runner-specific type-check command used locally and in CI.
- Keep runtime behavior tests separate from compile-time API tests. Use type tests only for supported public contracts such as inference, overloads, generics, discriminated unions, and rejected inputs.
- With Vitest, place compile-time assertions in the configured type-test pattern, commonly `*.test-d.ts`, and use `expectTypeOf`, `assertType`, or deliberate `@ts-expect-error` assertions. Remember that these files are statically analyzed rather than executed.
- Do not assume a passing type test proves runtime validation. TypeScript types disappear at runtime; exercise untrusted input through the real parser or validator.
- Prefer typed fixture builders and `satisfies` over `as`, `as unknown as`, or `any`. A cast can make an invalid fixture compile and hide a production mismatch.

```typescript
const validRequest = {
  productId: "product-1",
  quantity: 2,
} satisfies CreateOrderRequest;
```

- Import types from production instead of duplicating test-only versions. Keep test-only helper types small and derived from the public contract.
- Match the project's ESM/CommonJS and path-resolution configuration. Do not change import style merely to make mocking easier.

## Unit Tests

- Unit-test pure calculations, dense branching, parsers, value objects, and domain rules through exported behavior.
- Use table-driven tests for stable groups of equivalent cases, but introduce each new behavior through its own RED→GREEN slice first.
- Type the case table so missing or invalid cases fail compilation.

```typescript
const cases = [
  { amount: 0, expected: "free" },
  { amount: 1, expected: "paid" },
] as const satisfies readonly {
  amount: number;
  expected: "free" | "paid";
}[];
```

- Prefer exact assertions for business outcomes and error codes. Use partial matchers only for fields that are intentionally irrelevant to the behavior.
- Keep snapshots short and focused. Commit and review them as assertions; never update them blindly. Prefer targeted assertions when only a few fields matter.
- Do not test TypeScript `private` members, module internals, or an internal collaborator's call sequence.
- Test both branches of discriminated results or error unions when callers rely on the distinction.

## Integration Tests

- Enter through the real public adapter: an HTTP handler, command, queue consumer, repository interface, or application service.
- Compose the real production modules. Replace only external systems that the test does not own.
- Use the same schema and migrations as production. Prefer a real ephemeral database or service over an in-memory substitute when transactions, constraints, serialization, or provider behavior matters.
- Consider Testcontainers for disposable databases, brokers, or caches when the repository supports containers and the added fidelity justifies the startup cost.
- Give each test independent data, identifiers, and cleanup. Make tests safe under file-level parallelism and do not depend on execution order.
- Exercise success, validation rejection, dependency failure, and state invariants through the public interface. Verify persisted outcomes through a public read path where possible.
- For third-party HTTP, prefer a network-level fake or local test server, such as MSW, over mocking the application's HTTP client module. Define explicit success, refusal, timeout, and malformed-response handlers as needed.
- Reject unexpected outbound requests when the selected tool supports it. A silent default response can let an integration path bypass its intended boundary.
- Keep a smaller contract test for the external adapter when serialization, authentication, or response mapping must match a real provider.
- Use an actual listening socket only when networking behavior matters. Otherwise, framework request injection is acceptable when it runs the same middleware, routing, validation, and handler stack.

## UI Tests

- Use Testing Library-style queries that resemble user interaction. Prefer role and accessible name, then labels and visible text; use test IDs only as a fallback.
- Use `getBy*` for immediately present elements, `findBy*` for asynchronous appearance, and `queryBy*` for asserting absence.
- Interact through the project's user-event utility rather than calling component methods or mutating internal state.
- Use a DOM emulator for behavior that only needs DOM APIs. Use a real browser test when layout, focus, navigation, browser security, or unsupported Web APIs are part of the risk.
- Assert the user-visible error and recovery action, not framework component state.

## Async Code and Time

- Return or `await` every promise. Write `await expect(promise).rejects...`; omitting `await` can create a false positive.
- Prefer `async`/`await` over callback completion APIs. Do not mix a returned promise with a `done` callback.
- Use `expect.hasAssertions()` or `expect.assertions(n)` only when assertions live inside callbacks, loops, or conditional async paths and might otherwise never run.
- Treat unhandled rejections and uncaught exceptions as failures. Do not globally suppress them to make the suite green.
- Inject a clock when time is domain input. Use fake timers for scheduling behavior, advance them deliberately, and restore real timers after each test.
- Do not raise timeouts to conceal a missing `await`, leaked handle, unresolved promise, or nondeterministic poll. Use bounded polling only for genuinely eventual behavior.

## Fixtures, Isolation, and Mocks

- Create the smallest valid fixture and override only fields relevant to the test. Avoid a single mutable fixture shared across tests.
- Prefer builders that return fresh objects. Validate builder defaults against production types with return annotations or `satisfies`.
- Restore spies, module replacements, globals, environment variables, timers, and network handlers after each test. Use the runner's automatic restoration options when available.
- Give boundary fakes typed, intention-revealing modes such as `approved`, `declined`, `timeout`, and `malformedResponse`.
- Make an unconfigured fake fail loudly instead of returning permissive defaults.
- With Vitest versions that support typed module factories, prefer `vi.mock(import("./boundary.js"), factory)` over an untyped string so TypeScript checks the path and factory shape.
- Avoid broad auto-mocking. It can replace unmentioned exports with `undefined` and turn a production integration into a mock graph.

## Execution and CI

During each RED→GREEN cycle:

1. Run the single test or file and inspect the failure reason.
2. Run the nearest unit or integration suite after GREEN.
3. Run the full relevant runtime suite and type-check before completion.

In CI:

- run tests in non-watch mode with the repository's pinned package manager;
- fail on focused tests such as `.only` and report intentional skips;
- run type-checking even when the test runner transpiles TypeScript successfully;
- keep integration services disposable and pin their versions;
- use coverage to locate untested branches, not as proof that behavior and failure handling are correct;
- preserve logs and diagnostics needed to understand integration failures without exposing secrets.

## Official Sources

- [Vitest: Writing Tests](https://vitest.dev/guide/learn/writing-tests)
- [Vitest: Testing Types](https://vitest.dev/guide/testing-types)
- [Vitest: Testing Asynchronous Code](https://vitest.dev/guide/learn/async)
- [Vitest: Mock Functions](https://vitest.dev/guide/learn/mock-functions)
- [Jest: Getting Started with TypeScript](https://jestjs.io/docs/getting-started#using-typescript)
- [Jest: Testing Asynchronous Code](https://jestjs.io/docs/asynchronous)
- [Testing Library: About Queries](https://testing-library.com/docs/queries/about)
- [TypeScript: The `satisfies` Operator](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-4-9.html)
- [Testcontainers for Node.js](https://node.testcontainers.org/)
- [Mock Service Worker](https://mswjs.io/)
