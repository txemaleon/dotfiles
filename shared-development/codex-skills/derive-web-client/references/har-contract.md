# HAR contract

## Capture scope

Record one business action in a dedicated tab. Clear unrelated traffic first; do not include analytics, ad networks, passwords, payment details, account settings, private messages, or other users' data. Export the HAR only to a local, ignored workspace path.

The HAR is an input for reverse engineering a user-authorized workflow, not a deployable artifact. Delete it once the client and tests have been verified.

## Contract output

`har_contract.py` reads HAR 1.2-style entries and emits a stable JSON contract. An operation is deduplicated by HTTP method, origin, pathname, query-key set, and request-body MIME type. It retains only:

- origin, method, pathname, query-key names, and request-body MIME type;
- allowlisted non-secret request-header names and values;
- response status and MIME type;
- occurrence count and a deterministic operation name.

It replaces sensitive header and query values with no output at all. It intentionally does not retain request or response bodies.

## Authentication design

Use an explicit interface owned by the application, for example `getHeaders(): Promise<Record<string, string>>`. Supply official API credentials from the deployment's secret store or a local environment variable at runtime. Do not export browser cookies, Keychain entries, local storage, or HAR credentials into code.

If a site only accepts an authenticated browser session, retain a small browser-mediated adapter for that part rather than attempting to defeat its protections. The direct client can still cover public endpoints and post-login API calls where the service permits them.

## Client quality bar

Give every request a timeout and a bounded retry policy for transient failures only. Support pagination deliberately. Validate the smallest response shape needed. For writes, default to dry-run, add a clear apply gate, and use idempotency keys if available. Keep a fixture from the sanitized contract and test URL construction, headers, pagination, and error handling without network access.
