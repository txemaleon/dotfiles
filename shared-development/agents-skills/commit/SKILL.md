---
name: commit
description: Analyze all changes and create multiple atomic conventional commits grouped by logical purpose. Use when committing, staging changes, asked to commit work, or when the user says "commit".
allowed-tools: Read, Bash
model: haiku
context: fork
agent: general-purpose
---

# Atomic Conventional Commits

Be fast and concise. Don't overthink grouping — use obvious boundaries. Skip lengthy analysis.

Analyze all unstaged and staged changes, then create multiple atomic commits grouped by logical purpose.

## Process

1. Run `git status` and `git diff` to identify all changes
3. Group changes by:
   - Feature/functionality (same feature across files)
   - Type (fix, feat, refactor, docs, test, style, chore)
   - Scope (module, component, layer)
4. For each group:
   - Stage only the relevant files: `git add <files>`
   - Commit with conventional format: `type(scope): concise message`
5. Order commits logically (deps before dependents, infra before features)

## Conventional Commits Format

- `feat(scope):` new feature
- `fix(scope):` bug fix
- `refactor(scope):` code restructure, no behavior change
- `docs(scope):` documentation only
- `test(scope):` adding/updating tests
- `style(scope):` formatting, no code change
- `chore(scope):` maintenance, deps, config

## Rules

- Never create one big commit for unrelated changes
- Each commit should be atomic and revertable
- Scope is optional but preferred when clear
- Message: imperative mood, lowercase, no period, max 72 chars
- Do NOT push to remote unless explicitly asked
