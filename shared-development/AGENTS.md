# Global instructions

- Keep this file limited to durable preferences that apply across projects.
- Put project-specific instructions in the nearest project `AGENTS.md`.
- Do not add or broaden global rules unless the user explicitly asks. When editing this file, replace obsolete or redundant guidance instead of accumulating exceptions.
- Never contact a client or send any external communication on the user's behalf without first obtaining the user's explicit approval of that specific communication.
- Do not sidestep a user's problem with a workaround. Identify what the user is actually using, reproduce the reported failure, and determine its root cause before proposing alternatives.
- Report findings, decisions, status and results directly in the conversation. Do not create separate reports or documentation for the user to read unless explicitly requested.

## Codex goals

- Use a Codex goal for every user request that establishes a concrete outcome to complete in the session. This applies across code, research, writing, operations and other substantive work; an informal statement of intent or a plan is not a substitute for a goal.
- In the opening turns, always establish the objective and identify an automatic verification method whenever one is applicable. Capture acceptance requirements and constraints when they exist or materially affect the outcome; do not invent them merely to fill a template. If a missing detail would materially change the outcome and cannot be inferred safely, resolve it before creating the goal.
- As soon as that information is sufficient, create the goal before beginning execution. State the goal so that it preserves the outcome and its success conditions through context compaction; use a plan as a supporting execution aid only when useful.
- Keep the goal active across turns and context compactions until the complete outcome has been achieved. After a compaction, consult the active goal and continue from it instead of silently narrowing, replacing or abandoning the task.
- When the user adds a new objective or materially refines, expands or redirects the current one during the session, update the active goal before continuing substantive work. Reapply the same pattern to the changed scope: objective, applicable requirements and constraints, and verification. Do not leave a stale goal representing only the session's original scope; create a fresh goal when a distinct objective begins after the previous one is complete.
- Run the identified verification before completion and compare the result against every applicable requirement and constraint. When direct automatic verification is not applicable, use the strongest proportionate evidence available and state the limitation. Mark the goal complete only when the requested outcome is achieved and adequately verified; if verification fails, report the gap and keep the goal active unless the goal tool's blocking conditions are genuinely met.

## Scope and operational changes

- Create and manage scheduled tasks and cron jobs on `dev`, accessible through SSH (`ssh dev`) or a Codex thread running on `dev`. `tesseract` is no longer the execution host for these tasks.
- Treat the repository, systems and outcome named by the user as a hard scope boundary. Do not modify another repository or external system unless the user has explicitly authorized that target. If completing the request appears to require crossing that boundary, stop before editing, explain why it is necessary and obtain explicit approval for the additional target.
- Never expand a product or code change into operational work—such as schema migrations, deployment hooks or pipelines, readiness/runtime attestation, backup/restore or PITR, secrets, production configuration, infrastructure, or release hardening—unless the user explicitly requested that work or it is strictly required for the accepted behavior. When it is strictly required but was not requested, pause before making the change, describe the exact operational impact and tradeoff, and ask for approval.
- Review findings, performance opportunities and defensive hardening do not broaden the authorized scope. Record non-blocking improvements as optional follow-ups instead of implementing them. Use verification proportionate to the requested change; do not turn a small feature into a release-hardening exercise.
- Never run a production migration, deploy, push, release, restart or other external operational mutation without explicit authorization for that specific action, even when earlier implementation work was authorized.

## Codex thread titles

- Once the project and task are clear, rename the current Codex thread before completing the first substantive response when a thread-title tool is available.
- Use exactly `<PROJECT_CODE> - <concise task title>`, with the project code in uppercase and a space-hyphen-space separator.
- Keep the task title short and descriptive. Do not repeat the project name in it, and do not rename the thread again unless its scope changes materially.
- Use these stable project codes:
  - Renewable Grid Atlas: `RGA`
  - Sistema de notificaciones: `NTF`
  - Notion to Calendar: `N2C`
  - Notion to Maps: `N2M`
- For an unlisted project, prefer a code declared in the project's nearest `AGENTS.md`. Otherwise derive a stable 2-4 character uppercase code from the project name, using `2` for “to”, and keep using the same code throughout the thread.

## Code projects: shipping and verification cadence

- Apply this section only to work that changes code. For documentation, research, content, planning, configuration-only or other non-code work, do not introduce code-oriented workflows or review gates.
- For a multi-task or multi-phase objective, prioritize completing the whole requested outcome. Do not turn each intermediate slice into a release candidate.
- During implementation, run only the smallest focused checks needed to avoid accumulating broken code. Batch related work instead of repeating full suites after every task or phase.
- For ordinary non-incident work, run broad unit/integration/E2E suites, coverage, lint, typecheck, build, Docker or release gates once at final handoff only when they are proportionate to the change or required by the nearest project instructions. Prefer CI for checks it already runs reliably.
- Treat TDD and broad review skills such as `session-review` as project-level choices, not global defaults. Use them only when the user explicitly requests them or the nearest project `AGENTS.md` requires them. In their absence, choose focused verification proportionate to the change.
- An earlier broad gate is justified only when the user explicitly requests an intermediate release/deploy, or when a migration or similarly irreversible boundary must be verified before proceeding. Record intermediate results as provisional and never claim an unexecuted final gate passed.

## Debugging and active incidents

- When the user is debugging a failure or reports ongoing production errors, prioritize time to a safe, deployable fix over exhaustive completeness. Start with the actual failing path and inspect the most relevant logs, schema, migration state, recent deploy, or runtime evidence before widening the investigation.
- Once the root cause is confirmed, implement the smallest change that resolves it. Do not add adjacent refactors, cleanup, defensive hardening, release-process improvements, or speculative fixes to the incident response.
- Run the narrowest verification that reproduces the failure and proves the fix. Do not delay an incident fix for repository-wide tests, lint, builds, coverage, broad reviews, scope audits, or unrelated changed-file checks unless a specific one is necessary to establish the fix is safe or the user explicitly asks for it.
- Hand off the fix as soon as focused verification passes and let CI run broader gates when available. If deployment is explicitly authorized, use the project's defined release path and then verify that the reported production symptom has stopped.
- Record non-blocking concerns as follow-ups. Never keep an active incident waiting for polish or verification that does not materially reduce the immediate production risk.

## Cloudflare DNS and domain registration

- Use `cloudflare-codex` for Cloudflare zone, DNS, and Registrar operations. Never read, print, copy, log, or expose `/home/txemaleon/.config/cloudflare/tesseract-codex.json` or its token, and never bypass the wrapper with direct Cloudflare API calls.
- Read-only searches, availability checks, price checks, zone listings, registration listings, and DNS listings may run without additional approval.
- Before any DNS write or zone creation, show the exact intended change and obtain the user's explicit approval for that change. Zone creation and DNS deletion also require the wrapper's exact interactive confirmation.
- A domain purchase is billable and non-refundable. Always run `cloudflare-codex registrar plan DOMAIN`, present the exact domain, registration price, currency, current renewal price, and the fact that auto-renew is disabled, then obtain the user's explicit approval of that exact purchase in the current conversation. Only after that approval may `cloudflare-codex registrar purchase` be run in an interactive TTY using the fresh plan fields. Never infer approval from an earlier or general request.
- Stop if Cloudflare reports a premium domain, a changed price, an unsupported extension, `action_required`, or any ambiguous result. Never enable auto-renew, change registrant contacts, delete a zone, or alter billing details unless the user explicitly requests and approves that separate action.
