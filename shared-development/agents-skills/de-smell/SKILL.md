---
name: de-smell
description: Rewrite, edit, or review prose to remove obvious LLM/ChatGPT writing tells while preserving the author's facts, intent, and target audience. Use when the user asks to make copy sound less AI-written, less generic, less trope-y, more human, more natural, more editorial, more founder-written, or asks about LLM smells, AI smells, ChatGPT tells, de-smelling, anti-AI copy editing, humanizing text, or improving engagement without marketing fluff.
---

# De-smell

## Purpose

Remove patterns that make writing feel machine-generated without making it sloppy, cute, or over-stylized. The goal is not to "hide AI"; it is to make the piece read like a specific person had a reason to write it.

## Workflow

1. Identify the likely audience, medium, and job of the text.
2. Preserve claims, facts, sequence, constraints, and any intentional positioning.
3. Scan for LLM smells. For a deeper checklist, read `references/llm-smells.md`.
4. Decide what the piece should sound like: direct note, founder post, technical explainer, sales page, editorial essay, changelog, internal memo, or tutorial.
5. Rewrite in fewer, stronger moves. Prefer concrete nouns, lived constraints, and specific transitions over generic emphasis.
6. Remove language that announces sincerity, importance, clarity, or simplicity instead of demonstrating it.
7. Return either the revised copy only, or a short "changed because" note when useful.

## Editing Rules

- Keep the author's actual point. Do not add fake personal anecdotes, fake data, fake controversy, or unverifiable texture.
- Vary sentence shape, but avoid performative fragments when the original piece needs credibility.
- Replace generic contrast frames with concrete context: who could do what before, what broke, what is now possible, and why it matters.
- Prefer one precise example over three abstract benefits.
- Cut throat-clearing: "In today's world", "Let's be clear", "It is important to note", "This isn't just".
- Cut empty escalation: "game-changing", "fundamentally", "revolutionary", "seamless", "robust", "powerful", "unlock", unless the surrounding evidence earns it.
- Avoid repetitive rhetorical templates: "Not X. Y.", "No X. No Y. No Z.", "X? Boom. That's Y.", "The truth is", "Here's the thing".
- Do not overcorrect into bland corporate prose. Human writing can be uneven, opinionated, and specific.
- When editing Spanish, remove calques and AI-ish symmetry in the same way: "No es X, es Y", "Esto no va de X", "Lo importante es", repeated triads, and generic intensifiers.

## Useful Output Shapes

For a direct rewrite:

```text
Rewritten:
<copy>
```

For a review:

```text
Main LLM smells:
- <pattern>: <why it weakens the text>

Suggested rewrite:
<copy>
```

For high-stakes or user-facing copy, include a small diff-style explanation only after the rewrite. Keep it brief; the edited copy is the deliverable.
