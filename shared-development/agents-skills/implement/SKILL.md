---
name: implement
description: Implement a drafted plan via /tdd, then validate with /session-review. Use after planning phase, when the user says "implement" or "implement the plan", or when ready to execute a design.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash, Skill
---

# Implement

Thin orchestrator. The actual rules live downstream — don't duplicate them here.

## Process

1. **Build with `/tdd`** — drive the requested behaviors through red-green-refactor.
2. **Validate with `/session-review`** — once the plan is implemented, review the exact session diff independently against the accepted specification and repository standards. Fix hard findings before reporting done.
3. **Report** — summarize what shipped, both review verdicts, and any intentionally accepted residual risk.

## Non-negotiables (delegated, not duplicated)

- TDD discipline → owned by `/tdd`
- Spec fidelity, architecture, smells, correctness, tests, and maintainability → owned by `/session-review`
- Conventional atomic commits → owned by `/commit`

If a generic review rule conflicts with a documented project decision, the project decision wins. Update shared review policy in `/session-review`, not here.

## Failure modes

- `/tdd` skipped because "it's just a small change" → no. Every change goes through it.
- `/session-review` run but hard findings ignored → not done. Fix them or obtain an explicit decision to accept the risk.
- Session ends without both Spec and Standards verdicts → not done.
