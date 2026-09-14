---
name: tdd
description: Apply test-driven development with vertical red-green-refactor slices, risk-based integration coverage for critical paths, and explicit tests for validation, dependency failures, error contracts, state consistency, recovery, and idempotency. Use when building features or fixing bugs test-first, when the user mentions TDD or red-green-refactor, or when integration and failure-path testing are required.
---

# Test-Driven Development

## Principles

- Verify behavior through public interfaces, not implementation details.
- Name the public test seams explicitly: the stable boundaries where behavior enters the system and observable results leave it.
- Derive expected values from an independent source of truth, never by repeating the production calculation in the assertion.
- Exercise critical paths with integration tests that cross real production components.
- Cover success and representative failure behavior; a happy-path test alone does not complete a critical path.
- Work in vertical slices: one failing test, the minimum implementation, then the next behavior.
- Keep every failure deterministic and confirm that it fails for the intended reason.

Treat a path as critical when its failure could block a primary user outcome, corrupt or lose state, create security or financial exposure, or make recovery difficult. Prioritize by impact and likelihood rather than enumerating every theoretical edge case.

Before planning tests, read `CONTEXT.md` when it exists and the ADRs that apply to the area being changed. Reuse their domain language in seam names, test names, fixtures, and assertions, and respect recorded interface and architecture decisions.

Read [tests.md](tests.md) for test-level guidance and examples. For a TypeScript codebase, also read and apply [typescript-testing.md](typescript-testing.md) before planning tests. Read [mocking.md](mocking.md) before introducing test doubles. Use [interface-design.md](interface-design.md), [deep-modules.md](deep-modules.md), and [refactoring.md](refactoring.md) when shaping or simplifying an interface.

## 1. Plan Behaviors and Risks

Before changing production code:

1. Identify and name the public seam under test: its entry point, observable result, persistent effects, and external boundaries.
2. Identify the critical paths and invariants affected by the change.
3. Build a compact behavior matrix:

   | Behavior | Public seam | Success | Representative failure | State/error invariant | Test level |
   | --- | --- | --- | --- | --- | --- |
   | Primary user outcome | Stable boundary under test | Expected observable result | Highest-risk or most likely failure | What must remain true | Integration by default |

4. Prioritize behaviors instead of attempting exhaustive combinations.
5. Confirm material seam, interface, or contract decisions with the user. State reasonable assumptions and proceed when they do not change the requested behavior.

For each critical path, include, when applicable:

- the primary successful outcome;
- invalid or rejected input at the public boundary;
- a likely or high-impact dependency failure, such as refusal, timeout, or unavailable storage;
- the public error contract and the absence of unintended side effects;
- recovery, retry, rollback, compensation, or idempotency behavior when partial work or repetition is possible.

Use one representative case per distinct behavior class. Add more cases only when they exercise different branching, invariants, or risk.

## 2. Choose the Test Level

Use an integration test for a critical path unless the required infrastructure makes it impractical. Start from the real public entry point and exercise real internal components and persistence where feasible. Replace only true external boundaries with contract-faithful fakes, stubs, or local test servers.

Use focused unit tests for pure algorithms, combinatorial rules, and isolated edge cases. Keep a small number of end-to-end tests for wiring that only a deployed or near-production environment can prove. Do not substitute a collection of mocked unit tests for a critical-path integration test.

## 3. Run One Vertical Slice

### RED

1. Write one test for one behavior from the matrix.
2. Prefer the integration path when the behavior is critical.
3. Run the narrowest relevant test command.
4. Confirm that the new test fails because the behavior is missing or wrong—not because of syntax, fixtures, setup, or an unrelated defect.

### GREEN

1. Implement only enough production code to satisfy the behavior.
2. Run the new test until it passes.
3. Run the relevant surrounding suite to detect regressions.

Do not write all tests first and then all implementation. Repeat RED→GREEN for each behavior, using what the previous slice revealed. After establishing a critical success path, add its most important rejection or failure slice before declaring that path covered.

## 4. Test Error Handling as Behavior

For a failure-path test, assert the observable contract and the invariant it protects:

- stable error type, code, status, or retryability exposed to the caller;
- safe, useful messaging without secrets or irrelevant internal details;
- expected state after the failure, including no partial or duplicate writes;
- expected external effects, including effects that must not occur;
- rollback or compensation when the operation crosses transactional boundaries;
- retry, timeout, cancellation, and idempotency semantics when relevant;
- successful recovery after a transient failure when recovery is part of the contract.

Avoid vague assertions such as “throws an error.” Do not overspecify incidental wording, logs, stack traces, private calls, or implementation order unless they are themselves a supported contract.

## 5. Refactor While Green

After the relevant tests pass:

- remove duplication;
- deepen modules and simplify public interfaces;
- improve names and test fixtures;
- keep failure injection at system boundaries;
- run tests after each refactor step.

Never refactor while RED. Do not weaken assertions merely to make a test pass.

## Per-Cycle Checklist

```text
[ ] The test names an observable behavior and its relevant condition
[ ] The test uses a named public seam
[ ] Expected values come from a specification, worked example, known-good fixture, or another independent source of truth
[ ] A critical path is integration-tested through real internal components
[ ] The new test failed first, for the expected reason
[ ] The implementation is minimal for this behavior
[ ] The test would survive an internal refactor
[ ] Failure behavior checks the public error contract
[ ] Failure behavior checks state and side-effect invariants
[ ] The focused test and relevant surrounding suite pass
```

## Completion Checklist

```text
[ ] Every prioritized critical path has an integration success test
[ ] Every prioritized critical path has a representative negative or failure test
[ ] Validation, dependency failure, and recovery/idempotency were considered
[ ] Error responses distinguish expected, retryable, and unexpected failures where relevant
[ ] No critical behavior is proven only through mocked internal collaborators
[ ] TypeScript tests and fixtures type-check without unsafe escape hatches
[ ] Runtime tests and public type-contract tests both run when each is relevant
[ ] The full relevant suite passes
[ ] Remaining risks or intentionally omitted cases are reported
```
