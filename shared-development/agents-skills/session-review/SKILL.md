---
name: session-review
description: Review only the code changes produced in the current work session against the originating request or specification, the repository's own standards, and proportionate engineering verification. Use after implementing or modifying code, before final handoff or committing, or when the user asks to review this session's work.
---

# Session Review

Review the session change set along two independent axes:

- **Spec:** Does the change faithfully implement what this session was asked to accomplish, without omissions, incorrect behavior, or scope creep?
- **Standards:** Does the change follow the repository's documented standards and sound engineering practice, with appropriate tests and verification?

Run an evidence-based review in exactly one isolated, read-only subagent. Keep the two axes separate inside its report so strength in one cannot hide failure in the other. Review only session-owned changes and the affected feature slices; never expand into a repository-wide audit.

Read [references/review-checklist.md](references/review-checklist.md) completely before reviewing.

## Select Execution Mode

- **Reviewer mode:** When the prompt identifies this agent as the isolated reviewer and supplies the repository, session base, session head, included worktree paths, spec sources, and standards sources, perform the review directly. Do not launch another subagent.
- **Orchestrator mode:** Otherwise, establish scope and evidence, then launch exactly one isolated reviewer governed by this skill and its checklist.

Never create nested reviewers. If no subagent facility is available, report the limitation instead of reviewing in the orchestrator context.

## Establish Exact Session Scope

1. Resolve the repository root.
2. Use a fixed point explicitly supplied by the user when present. Otherwise derive the commit immediately before this session's work from the conversation and Git state.
3. Include session commits plus staged, unstaged, and untracked paths that belong to this session.
4. Exclude pre-existing branch changes and unrelated user work.
5. Verify the base resolves and the resulting change set is non-empty.
6. Map changed production files to the affected features or bounded contexts. Inspect neighboring code only as needed to understand changed contracts and established patterns.

Use merge-base comparison for a user-supplied branch or tag. Use the exact session-base commit when the session boundary is known. If ownership cannot be determined reliably, ask one concise scoping question rather than reviewing the whole branch.

## Identify Review Sources

### Spec sources

Build the session specification from the most direct available evidence:

1. The user's requests, decisions, and corrections in this session.
2. An accepted plan or task list from this session.
3. A spec, issue, ticket, or acceptance criteria explicitly referenced by the user or session commits.
4. Matching repository documents under `docs/`, `specs/`, or a project-defined planning location.

Do not invent requirements. Record unresolved contradictions or genuine ambiguity as `NOT VERIFIED`. A conversational request is a valid spec; do not require a separate document or issue tracker.

### Standards sources

Read applicable sources in precedence order:

1. System and user constraints.
2. The nearest `AGENTS.md` and other repository instructions.
3. Project standards such as `CONTRIBUTING.md`, architecture documents, `CONTEXT.md`, and relevant ADRs.
4. Tool-enforced configuration for formatting, linting, types, tests, and coverage.
5. Established patterns in the affected feature.
6. The checklist's engineering and smell baseline.

More specific documented project decisions override generic preferences. Treat baseline smells as judgement calls, not automatic violations. Do not repeat diagnostics already reported precisely by tooling.

## Collect Evidence

Pass only factual session evidence:

- exact change range and included worktree paths;
- session spec and standards sources;
- Red, Green, and Refactor observations, or `not available`;
- focused and final verification commands with exit statuses;
- exact coverage metrics when collected;
- repository state before and after verification.

Never manufacture process evidence. Use the repository's documented final checks. Measure coverage when the project or user requires a threshold, when changed critical behavior would otherwise remain materially uncertain, or when coverage is already part of the normal final gate. Report exact metrics without adding artificial tests merely to reach a number.

## Launch The Reviewer

Launch one isolated read-only subagent with this prompt shape:

```text
Use $session-review in reviewer mode.
Full Repository Path: <absolute path>
Session Base: <commit before the session>
Session Head: <current commit or HEAD>
Include Session Worktree Changes: <yes|no, with exact owned paths>
Session Summary: <factual summary>
Spec Sources: <conversation requirements and document/issue paths>
Standards Sources: <instruction and standards paths>
TDD Evidence:
- Red: <evidence or "not available">
- Green: <evidence or "not available">
- Refactor: <evidence or "not available">
Verification Evidence: <commands, statuses, metrics, or "not available">
Custom Constraints: <constraints or "none">
```

The reviewer must apply the checklist completely and return both axis verdicts plus the global result. Do not duplicate its review in the orchestrator.

## Return The Report

Preserve the reviewer's evidence and ordering:

1. Findings ordered by severity and labelled `Spec` or `Standards`.
2. Exact session scope and exclusions.
3. Spec compliance, requirement by requirement.
4. Standards compliance for applicable categories.
5. Verification commands, metrics, limitations, and TDD evidence.
6. Independent `Spec` and `Standards` verdicts, followed by the global result.

Do not fix findings inside this skill. The caller may fix them and run `$session-review` again.
