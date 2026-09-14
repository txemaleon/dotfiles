# LLM Smells Reference

Use this checklist when a user asks why copy feels AI-written, or when a rewrite should specifically remove ChatGPT-style patterns.

## High-Signal Smells

- **Binary contrast slogan:** "It's not X, it's Y", "This is not about X. It is about Y."
- **Stacked negation:** "No setup. No fees. No complexity."
- **Rhetorical label punch:** "This thing? That's the platform shift."
- **Announcement of authenticity:** "That's not marketing fluff", "This is real", "Let's be honest."
- **Generic before/after ladder:** "Before this... Now... That changes everything."
- **Over-neat triads:** three benefits, three objections, three short sentence fragments, repeated too cleanly.
- **Inflated abstraction:** "fundamentally changes", "genuine platform", "new era", "unlocks possibilities."
- **Frictionless magic:** "Just code + deploy + it works", "seamless", "effortless", "with one command" when the real caveats matter.
- **Overexplained obviousness:** defining common terms for an audience that already knows them.
- **Universalizing claims:** "everyone", "never", "always", "the entire ecosystem", unless sourced.
- **Synthetic enthusiasm:** "huge opportunity", "massive unlock", "game changer", with no concrete stakes.
- **Same-length cadence:** many medium-length sentences with similar punctuation and no natural interruption.
- **Generic empathy intro:** "I understand why...", "I know how frustrating...", when it does not add new information.
- **Glossy SaaS vocabulary:** "leverage", "streamline", "robust", "powerful", "scale", "delight", "frictionless."
- **Safety net endings:** "Ultimately...", "At the end of the day...", "Whether you're X or Y..."

## Replacement Moves

- Name the real constraint: hosting, cron jobs, OAuth, retries, billing, permissions, review process, docs, distribution.
- Use a concrete actor: solo builder, consultant, internal tools team, plugin developer, admin, customer success team.
- Replace "it changes everything" with the exact behavior that changes.
- Keep one sharp sentence instead of three slogan fragments.
- Let uncertainty sound normal: "probably", "for teams already living in Notion", "if the runtime limits hold up."
- Preserve caveats when they are the reason a human would trust the piece.
- Use domain-specific texture. A platform post can mention SDKs, deploy flow, auth, background jobs, hosting, versioning, limits, and distribution.

## Before/After Examples

Avoid:

```text
No servers. No DevOps. No monthly AWS bill. Just code + deploy + it works.
```

Prefer:

```text
The interesting part is that the runtime sits inside Notion's infrastructure. For a lot of small automations, that removes the awkward middle layer: a tiny server kept alive only to listen for events and call the API back.
```

Avoid:

```text
That's not marketing fluff. This fundamentally changes what Notion is.
```

Prefer:

```text
This is bigger than a nicer API. Notion is moving from "a tool you integrate with" toward "a place where the integration can actually run."
```

Avoid:

```text
And the entire developer ecosystem around this platform? It's three days old. That's the opportunity.
```

Prefer:

```text
The timing matters too: if the platform only launched this week, the obvious examples, templates, and distribution channels have not settled yet.
```

## Final Pass

Ask:

- Would the target reader believe this came from a person with a stake in the topic?
- Is there at least one concrete detail that could not apply to any product announcement?
- Did any sentence survive only because it sounds punchy?
- Are claims calibrated to the evidence?
- Does the rewrite keep the author's intent instead of sanding it into generic "human" prose?
