---
name: recall
description: Use when user asks "what do I/you know about X" or needs information from memory
allowed-tools: Bash, Read
user-invocable: true
---

# Recall

Search the local knowledge base using qmd vector search.

## When to Use

- User asks "what do I know about X"
- User asks "what do you know about X"
- Need to find relevant context from memory before answering
- Looking for previously stored information, decisions, or ideas

## Availability

Resolve `qmd` from `PATH`; never assume a Homebrew path. Before searching, run:

```bash
QMD="$(command -v qmd)" || {
  echo "qmd is not installed; use a project-local .memory search when available" >&2
  exit 1
}
"$QMD" status
```

If `qmd` is missing or has no configured collections, do not invent results. Prefer a project-local `.memory/` search when one exists; otherwise report that global recall is not configured on this machine.

## Collections

| Collection | Path | Content |
|------------|------|---------|
| ideas | knowledge-base/ideas/ | Product concepts, brainstorms |
| self | knowledge-base/self/ | Values, goals, reflections |
| operations | knowledge-base/operations/ | Household, travel |
| publishing | knowledge-base/publishing/ | Blog drafts, content strategy |

Config: `~/.config/qmd/index.yml`

## Commands

```bash
# Text search (BM25)
"$QMD" search "query"

# Vector search (semantic)
"$QMD" vsearch "query"

# Hybrid search (BM25 + vector + rerank) — best quality
"$QMD" query "query"

# Get specific document section
"$QMD" get docs/path.md:10 -l 40

# Check index status
"$QMD" status

# Update index after file changes
"$QMD" update
```

## Execution Steps

1. Resolve `QMD="$(command -v qmd)"` and verify `"$QMD" status`
2. Run `"$QMD" update` if files were recently changed
3. Run `"$QMD" search "query"` for keyword matches
4. If keyword search is insufficient, try `"$QMD" vsearch "query"` for semantic matches
5. Read the top matching files using the Read tool for full context
6. Synthesize and present findings to the user, citing file paths

## Notes

- Index lives at `~/.cache/qmd`
- Uses local models (embeddinggemma-300M, qwen3-reranker-0.6b) — no cloud API needed
- Always update index before searching if new files were created in the session
