# Session Review Checklist

Apply every relevant item to the exact session change set. Base conclusions on the diff, neighboring contracts, tests, commands, or supplied session evidence.

## Status And Severity

- `PASS`: Direct evidence supports the requirement.
- `FAIL`: Direct evidence shows a defect, violation, omission, or unmet mandatory threshold.
- `NOT VERIFIED`: Evidence is insufficient for a material conclusion.
- `N/A`: The category cannot apply; explain why.

Classify findings as Critical, High, Medium, or Low by user impact, data/security risk, operational consequence, and likelihood. A possible smell without demonstrated impact is normally Low or an observation, not a hard failure.

## Scope Integrity

- Compare the exact session base through session head and add only explicitly session-owned worktree paths.
- List changed production files, tests, migrations, configuration, and public contracts.
- Map changes to affected features or bounded contexts.
- Inspect neighboring code only to evaluate changed behavior, dependency direction, compatibility, and established conventions.
- Exclude unrelated legacy problems unless the session change introduces, depends on, or worsens them.

## Spec Axis

Build a compact requirement ledger from the supplied spec sources. For each requirement, record `PASS`, `FAIL`, or `NOT VERIFIED` and cite its source.

Verify:

- Every requested behavior and acceptance criterion is implemented.
- The observable behavior matches the request, not merely its approximate shape.
- Validation, error behavior, state changes, and side effects match the agreed contract.
- Explicit non-functional requirements such as compatibility, accessibility, performance, security, or migration behavior are satisfied.
- No requested behavior is only partially implemented or hidden behind an unfinished path.
- No unrequested product behavior, abstraction, dependency, migration, or compatibility burden was added without a demonstrated need.
- Tests prove the requested behavior rather than an easier substitute.

Distinguish missing behavior, incorrect behavior, and scope creep. Do not reinterpret an ambiguous request to make the implementation pass.

## Standards Axis

### Repository standards first

- Apply the nearest repository instructions, documented conventions, relevant ADRs, domain vocabulary, and tool configuration.
- Prefer an established project pattern when it remains suitable.
- Treat a documented project decision as authoritative over the generic baseline.
- Flag contradictions between standards rather than silently choosing the convenient one.

### Structure and dependency direction

- Keep each changed feature cohesive and give every module a clear owner and reason to change.
- Keep business policy independent from UI, transport, persistence, frameworks, and vendors where the project architecture calls for that separation.
- Keep entrypoints and adapters thin; translate external models and errors at boundaries.
- Express external capabilities through narrow, consumer-oriented boundaries when dependency inversion is useful.
- Keep composition explicit; avoid service locators, hidden globals, import-time side effects, and inappropriate intimacy.
- Do not impose `application/domain/infra`, DDD, hexagonal architecture, repositories, ports, or factories when the repository and complexity do not justify them.
- When the project does use DDD or hexagonal architecture, verify ubiquitous language, bounded-context ownership, protected invariants, inward dependencies, and adapter translation.

### Design and maintainability

- Keep public APIs small, typed, explicit, and difficult to misuse.
- Prefer cohesive modules, clear names, simple control flow, and composition over inheritance unless substitutability is real.
- Remove duplication only when it represents the same knowledge.
- Avoid speculative abstraction, needless compatibility layers, dead code, and indirection without a meaningful consumer.
- Apply SOLID as design reasoning, not as a demand for one interface or class per concept.
- Ensure a change remains locally understandable and does not require scattered edits for one concept without good reason.

### Correctness and operational quality

- Validate untrusted input at the boundary and protect domain invariants at their owner.
- Model errors explicitly and preserve useful causes without exposing secrets.
- Define transaction, consistency, idempotency, retry, timeout, cancellation, concurrency, and rollback behavior where relevant.
- Bound parallelism, resource use, collections, retries, and external waits.
- Avoid races, duplicate side effects, unhandled asynchronous work, fragile parsing, unnecessary I/O, and N+1 behavior.
- Keep configuration external and validated; avoid environment-specific literals.
- Preserve backward compatibility or provide an intentional migration path for APIs, events, schemas, and persisted data.
- Make migrations deterministic, ordered, and safe for deployed data; make rollback possible when practical.
- Add proportionate logs, metrics, or traces at operational boundaries without sensitive data.
- For interface changes, verify accessibility, keyboard behavior, loading/error/empty states, responsiveness, and stable rendering when applicable.

### Test quality and TDD evidence

- Test every changed critical behavior through a stable public seam, including representative success and failure behavior.
- Assert observable contracts and state/side-effect invariants rather than private calls or incidental implementation order.
- Derive expected values from an independent source of truth; reject tautological assertions.
- Keep tests deterministic, isolated, readable, and independent of execution order.
- Keep mocks at real boundaries and contract-faithful; do not mock internal collaborators to simulate the implementation.
- Include a regression test that fails for the original defect when fixing a bug.
- Use integration tests for critical paths when practical and focused unit tests for pure or combinatorial logic.

Evaluate session process separately:

- `Red`: A focused test was observed failing for the intended missing behavior or defect.
- `Green`: The minimal implementation made it pass.
- `Refactor`: Structure improved while relevant tests remained green.

Missing process evidence is `NOT VERIFIED`; passing tests written afterward do not prove TDD. TDD evidence is mandatory only when the user, project, or invoked implementation workflow required TDD.

### Verification and coverage

- Use the repository's documented final verification commands and run broad gates once after implementation is complete.
- Report exact commands and exit statuses. Confirm whether verification changed the worktree.
- Apply user- or project-defined coverage thresholds exactly.
- Without a mandated threshold, judge whether prioritized critical behaviors and risks are covered; report available per-file statements, branches, functions, and lines as evidence rather than inventing a universal percentage.
- Treat missing required tooling or metrics as `NOT VERIFIED`.
- Fail uncovered critical behavior even when aggregate coverage is high.
- Do not demand low-value tests or weaken exclusions solely to reach 100%.

## Smell Baseline

Use these as labelled heuristics. Cite the changed hunk and explain the concrete consequence; do not fail a change merely because a label can be attached.

- **Mysterious Name:** A name hides what a value or operation means.
- **Duplicated Code:** The same knowledge or decision is encoded in multiple changed locations.
- **Feature Envy:** Logic depends more on another object's data than its own.
- **Data Clumps:** The same related values repeatedly travel together and lack a concept.
- **Primitive Obsession:** A primitive represents a domain concept with meaningful invariants or behavior.
- **Repeated Switches:** The same condition on the same kind appears in several places.
- **Shotgun Surgery:** One logical change requires scattered edits across unrelated owners.
- **Divergent Change:** One module changes for multiple unrelated reasons.
- **Speculative Generality:** Abstraction or configurability exists for no current requirement.
- **Message Chains:** Callers navigate another object's internals through long chains.
- **Middle Man:** A layer delegates without adding policy, translation, or useful stability.
- **Refused Bequest:** An implementation cannot honor the abstraction it inherits.

## Required Report

Return these sections in order.

### Findings

Order findings by severity. For each include:

- Axis: `Spec` or `Standards`
- Severity
- Feature
- `file:line`
- Source requirement or standard
- Evidence and impact
- Smallest appropriate remediation

Do not list compliant items as findings. Mark smell observations as judgement calls.

### Scope

State the exact comparison, included worktree paths, changed production files, affected features, and exclusions.

### Spec Compliance

List every requirement with its source, status, and concise evidence.

### Standards Compliance

Report each applicable category as `PASS`, `FAIL`, `NOT VERIFIED`, or justified `N/A`:

- Repository standards
- Structure and dependency direction
- Design and maintainability
- Correctness and operational quality
- Test quality
- Red
- Green
- Refactor
- Coverage and verification

### Verification

List commands, exit statuses, coverage metrics when available, tooling limitations, TDD evidence, and whether the worktree remained unchanged.

### Verdicts

- `Spec`: `PASS`, `FAIL`, or `NOT VERIFIED`.
- `Standards`: `PASS`, `FAIL`, or `NOT VERIFIED`.
- `Global`: `PASS` only when both axes pass; `FAIL` when either axis fails; otherwise `NOT VERIFIED`.

List the blocking categories after any non-passing verdict.
