---
name: debug
description: Debug a bug using hypothesis-driven instrumentation and runtime logs. Use when debugging, investigating bugs, fixing errors, or when the user says "debug" or describes unexpected behavior.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

# Hypothesis-Driven Debugging

Debug the described bug using runtime logs and iterative verification.

## Process

### 1. Describe
User describes the bug. Do NOT attempt immediate fix.

### 2. Hypothesize
- Read relevant code
- Generate 3-5 hypotheses about root cause
- List each hypothesis with reasoning

### 3. Instrument
- Add logging statements to test each hypothesis
- Log: variable states, execution paths, timing
- Mark logs clearly (e.g., `[DEBUG-H1]`, `[DEBUG-H2]`)

### 4. Reproduce
Ask user to reproduce the bug and provide logs.

### 5. Analyze
- Match logs to hypotheses
- Identify root cause from runtime data
- Generate minimal, targeted fix

### 6. Verify
- Apply fix
- Ask user to reproduce again
- If fixed: remove all instrumentation, confirm
- If not fixed: add more logging, repeat from step 4

## Rules

- Never guess fixes without runtime data
- Prefer 2-3 line fixes over speculative rewrites
- Keep instrumentation clearly marked for easy removal
- Human verifies each fix attempt
- Iterate until user confirms bug is resolved
