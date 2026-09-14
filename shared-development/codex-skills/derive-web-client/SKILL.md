---
name: derive-web-client
description: Derive safe, deterministic HTTP clients, CLIs, or scripts from a recorded web workflow (HAR) so recurring reads and actions do not require browser automation. Use when a user asks to automate a website, convert browser/network traffic into a library or CLI, create a client from a HAR file, reduce browser-control cost, or make a repeatable web workflow.
---

# Derive Web Client

Build a direct HTTP client from a narrowly recorded browser workflow. Use the browser only to discover and verify a workflow; use the generated client for repeat execution.

## Workflow

1. **Classify the target.** Prefer an official API when one exists. Otherwise derive a client only for stable, first-party XHR/fetch requests. Keep browser automation for CAPTCHA, WebAuthn, interactive OAuth, rendering-dependent work, or sites that block direct clients.
2. **Record one action.** In the user-authorized session, perform the smallest complete workflow and export a HAR. Do not export unrelated traffic. Treat the HAR as secret material: it may contain cookies, bearer tokens, personal data, and request bodies.
3. **Create the contract.** Run:

   ```bash
   python3 scripts/har_contract.py --har /absolute/path/workflow.har --out /absolute/path/web-client-contract.json
   ```

   The script produces a sorted, credential-free contract and never emits raw cookies, authorization values, sensitive query values, or request-body values. Review the output before using it.
4. **Implement the smallest suitable artifact.** Generate a TypeScript library for reuse by code, a CLI for operational tasks, or a focused script for a single job. Model authentication as an injected provider or runtime environment input; never copy values from the HAR into source, fixtures, Git, or logs.
5. **Validate without the browser.** Add mocked transport tests from the sanitized contract, then make one opt-in live call. Assert status, minimal response shape, pagination, rate-limit handling, and idempotency/retry behaviour. Log redacted request metadata only.

## Implementation Rules

- Preserve only headers the server demonstrably needs. Make `Cookie`, `Authorization`, CSRF/XSRF, API-key, and similar credentials runtime-only inputs.
- Keep request construction explicit: typed input, URL/path, query encoding, payload serialization, timeouts, retry policy, and response validation.
- Do not replay mutating operations by default. Require an explicit `--apply`/confirmation boundary and use idempotency keys when supported.
- Do not bypass CAPTCHAs, access controls, rate limits, or a site's terms. Prefer its documented interface.
- Re-record and regenerate the contract when an endpoint changes; do not make a fragile client silently fall back to browser clicks.

## Output Choice

| Need | Artifact |
| --- | --- |
| Reuse from an application | Small typed library with injected transport/auth |
| Operator task | CLI with `--dry-run` and explicit mutating flags |
| One repeatable report/export | Focused script plus scheduled runner if authorized |
| Login, CAPTCHA, dynamic UI, or anti-bot challenge | Keep a bounded browser workflow |

Read [references/har-contract.md](references/har-contract.md) before capturing authenticated traffic or designing request authentication.
