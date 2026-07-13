# Prompt Quality Evaluator — Claude Code edition

## Tags
prompt-engineering, context-engineering, claude-code, hooks, quality-gate

## What it is

A gate that checks *your* prompt against the 6 most common mistakes **before** Claude acts on it. The
Copilot version was a block of text you had to paste and hope the model honored. In Claude Code there
are **three** ways to run it, from cheapest to strongest:

| Tier | Mechanism | Always fires? | Cost | Smart? |
|------|-----------|---------------|------|--------|
| 1. Heuristic (default, shipped) | `UserPromptSubmit` command hook (`prompt-check.sh`/`.ps1`) | ✅ every prompt | free | crude (length/emptiness only) |
| 2. Semantic (opt-in) | `UserPromptSubmit` **prompt hook** (`type: "prompt"`) | ✅ every prompt | 1 fast model call/prompt | ✅ real 6-mistake check |
| 3. Manual | Paste the checklist into `CLAUDE.md` | ✅ (soft) | free | model-judgment |

Tier 1 ships enabled. Tier 2 is documented below and **off by default** because it spends a model call
on every prompt — turn it on if quality matters more than that marginal cost.

## The 6 mistakes it checks

1. **No context** — the ask doesn't say what you need or what it's for. → State the goal + the use.
2. **No perspective** — no audience / level given, so output is generic. → Name the reader and level.
3. **No examples** — "in my style" with no sample. → Paste 2-3 examples of the format you want.
4. **Hallucination risk** — asks for specific facts/numbers/dates without a verify escape hatch. → Add
   "if unsure, say 'needs verification' instead of guessing."
5. **Conflicting instructions** — "concise but thorough", or data mixed with commands. → Separate with
   tags: `<document>…</document>` vs `<instruction>…</instruction>`.
6. **No output format** — list vs prose, length, count unspecified. → State the exact shape you want.

Verdicts: **0 issues** → run normally · **1 issue** → run + one-line suggestion · **2+ issues** →
stop, show what's wrong + a ready-to-use improved prompt.

## Tier 2 — wire the real semantic gate (opt-in)

Add this block to `.claude/settings.json` under `hooks` (it *replaces* the command hook for
`UserPromptSubmit`, or runs alongside it). `$ARGUMENTS` receives the hook-input JSON (which includes
your `prompt`). A prompt hook returns a decision; here we use it to inject advice, not to hard-block:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "prompt",
            "model": "claude-haiku-4-5-20251001",
            "prompt": "You are a prompt-quality gate. Evaluate ONLY the user's prompt in $ARGUMENTS against these 6 mistakes: (1) no context, (2) no audience/level, (3) no examples when style/format is requested, (4) specific facts asked without a verify escape hatch, (5) conflicting instructions or data-not-separated-from-command, (6) no output format. Count issues. If 0: return additionalContext ''. If 1: return a one-line suggestion. If 2+: return a short list of the issues plus a rewritten, ready-to-use prompt. Never block; only advise via additionalContext. Be terse."
          }
        ]
      }
    ]
  }
}
```

Notes:
- Uses **Haiku** to keep the per-prompt tax minimal. Prompt hooks have a 30s timeout.
- Keep it advisory (`additionalContext`), not blocking — a hard block on every imperfect prompt is more
  friction than it's worth. (This matches the Balanced enforcement stance of the bundle.)
- Agent-based hooks (`type: "agent"`) can go further and inspect files before advising, but they spawn
  a tool-using subagent per prompt — usually overkill for a quality gate.

## Bonus
- Always verify AI-generated facts/numbers/sources before shipping them.
- Treat the first response as a draft — iterate with follow-ups instead of restarting.
