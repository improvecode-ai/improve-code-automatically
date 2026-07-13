# CLAUDE.md — Prompt Quality Gate

> **How to install:** merge the "## Prompt Quality Gate" section below into your repository's
> root `CLAUDE.md` (create one if it doesn't exist). Claude Code loads `CLAUDE.md` into context
> every session, so these rules are always available; the `UserPromptSubmit` hook in
> `.claude/settings.json` re-surfaces the short checklist on every prompt.
>
> **Source of truth:** `docs/prompting-best-practices-for-developers.md`. These rules are derived
> from that doc — when it changes, update this file to match. (Adjust the path if you keep the doc
> elsewhere.)

## Prompt Quality Gate

Before acting on any coding request, silently check it against the rules below.

- If it's clear and specific enough to act on, **proceed normally** — no commentary on prompt quality.
- If something important is missing, **don't generate the full solution yet**. Reply briefly with: (1) the 1–3 specific gaps, then (2) a stronger version of the request, filling gaps from this repo's patterns and marking any assumption. Then proceed on that basis.
- If the developer says "just do it" / "proceed as-is", skip the gate.

Keep gate responses short — the goal is to save round-trips, not to lecture.

### Rules

1. **Single task** — one task per request. If bundled ("fix the bug, add tests, clean up imports"), split it or ask which to do first.
2. **Specific criteria** — an action needs a defined target, not a vague quality. Flag "clean up", "optimize", "make it better" when no measurable goal is given.
3. **Constraints** — what must not change. Default if unstated: no new dependencies, no public-signature changes, don't touch unrelated files or tests.
4. **Context** — follow an existing pattern. If none is named, use the closest example in the repo.
5. **Output format** — diff vs. full file, code-only vs. code+explanation, tests or not. Default: minimal diff + one-line rationale.
6. **Perspective over persona** — for specialized work (security, performance), restate the concrete goal and what to check for rather than relying on a role label.

Task-specific rules load separately: tests via the `writing-tests` skill (`.claude/skills/writing-tests/`), bug review via the `/bug-review` command (`.claude/commands/bug-review.md`).
