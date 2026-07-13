<!--
  Context Engineering Guardrails — see ./context-engineering-rules-explained.md for the feasibility map.
  Keep this file lean: file refs, not pasted code. HTML comments like this cost 0 tokens (stripped
  before the file enters context). The .claude/hooks enforce the rules that can be forced; this file
  covers the soft rules the model applies by judgment.
-->

# Context Engineering Guardrails

## RULE #0 — self-calibrate before answering
Before a non-trivial answer, silently classify: **task** (simple | medium | complex), **conciseness
mode**, and whether the **session model** fits. Only surface it if something is off (e.g. "this is
complex — consider `/model opus`"). Don't print the block on every trivial reply — that is itself token
waste. The `UserPromptSubmit` hook re-points to this rule each turn.

## Model selection (Claude Code reality)
Model is chosen per **session** (`/model`) and per **subagent** — there is no mid-task dropdown. So:
- Pick the session model up front for the dominant task.
- **Route cheap work** (file search, greps, lookups, running tests) to the `explore-haiku` subagent —
  Haiku is ~5–15× cheaper and keeps that work out of the main context.

| Task | Type | Where |
|------|------|-------|
| Boilerplate/CRUD, rename, docs, tests for known code | simple | Haiku session or subagent |
| Feature, debug a known error, refactor, review | medium | Sonnet session |
| Architecture, security audit, subtle logic/race bug | complex | Opus session |
| Search / lookups / test runs (any task) | — | delegate to `explore-haiku` |

## Conciseness
Answer first. No preamble, no "Here's…", no summary of what you just did, no tips/notes unless asked or
safety-relevant. Output tokens cost ~3–5× input.

## Caveman style — SIMPLE tasks only
Simple task → compress: `keyword: value`, `action -> result`, no articles/grammar filler.
Medium/complex → normal prose (explanations prevent costly correction rounds). Never caveman a
debugging or design answer.

## Session hygiene
Long session or context bar high → suggest `/compact`. After a real break → `/clear` + fresh session
re-caches faster than continuing a bloated one. Don't re-explain context already established.

## Think in code
Never dump raw logs/files/CLI output into context. Filter first: `rg ERROR log | tail -20`, a script
that returns only the answer. Up to ~98% fewer input tokens on large data. (A `PreToolUse` hook blocks
the worst offenders — but do this by default, not because a hook forced you.)

## Targeted references
Read a **range**, not a whole file: use `offset`/`limit` or grep to the function first. Point at
`file.ts:getUser()`, not the 2000-line file. (Enforced: whole-file Reads of large files are denied.)

## CLI over MCP
Prefer `gh`, `git`, `rg`, `jq` with selective flags (`gh issue view N --json title,body`) over MCP
tools that return verbose JSON. Pipe/filter before output enters context. Use `rg`, never recursive
`grep` (denied).

## Input efficiency
Read the minimum needed. If the location is unknown, ask or grep — don't slurp the repo "to be safe".
