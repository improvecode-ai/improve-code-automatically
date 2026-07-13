# Claude Code Prompt Quality Gate

A self-checking prompt gate for Claude Code. Before Claude acts on a coding request, it checks
the request against a small set of prompt-quality rules and, if something important is missing,
returns the gaps plus a stronger version before proceeding — so you don't burn tokens (or land
bad code) on a vague prompt.

This is the Claude Code counterpart to the sibling `coding-prompt-quality-gate-copilot/` bundle.
Same rules, different delivery mechanisms.

## How it maps to Claude Code

Claude Code has richer primitives than a single instructions file, so each piece uses the right one:

| Piece | Mechanism | Fires |
|---|---|---|
| Core gate (6 rules) | `UserPromptSubmit` **hook** in `.claude/settings.json` + rules in `CLAUDE.md` | **every prompt**, automatically |
| Test-writing rules | **skill** `.claude/skills/writing-tests/` | best-effort, auto when working on tests |
| Bug review | **slash command** `/bug-review` | on demand |

The hook is the "always fires" piece — it's the only Claude Code mechanism that runs on *every*
prompt before Claude acts. A skill wouldn't (the model decides when to load it) and a slash command
wouldn't (you'd have to type it every time).

## File layout (already arranged in this bundle)

```
CLAUDE.md                                        # core gate: 6 rules + explanations (merge into your repo-root CLAUDE.md)
.claude/
  settings.json                                  # wires the UserPromptSubmit hook (inline echo — no script)
  skills/
    writing-tests/
      SKILL.md                                    # loads when working on tests
  commands/
    bug-review.md                                 # /bug-review
docs/
  prompting-best-practices-for-developers.md      # SOURCE OF TRUTH for the rules
```

## Install

1. Copy `CLAUDE.md`, `.claude/`, and `docs/` into the root of your repository.
   - **`CLAUDE.md`** — if you already have one, merge the "## Prompt Quality Gate" section into it
     (**required** — the hook's checklist points at these rules for the full detail).
   - **`.claude/settings.json`** — if you already have one, merge the `hooks.UserPromptSubmit`
     entry into it rather than overwriting.
2. **Restart Claude Code** (or start a new session) so it loads the new hook and `CLAUDE.md`.
3. Done. The gate now runs on every prompt. The `writing-tests` skill loads when you work on tests;
   trigger a structured bug review with `/bug-review` (optionally naming a file or function).

No runtime prerequisite — the hook is a plain `echo` and runs under either shell Claude Code uses
for hooks (Git Bash or PowerShell). Nothing to install.

## How the hook works

`.claude/settings.json` registers a `UserPromptSubmit` hook whose command is a single-line `echo`.
For `UserPromptSubmit`, a hook's stdout on exit 0 is injected into Claude's context — so every
prompt gets a short, high-salience reminder of the 6 checks plus the proceed/gap instruction. The
full rules with explanations live in `CLAUDE.md` (always in context), so the per-prompt reminder
stays compact and token-light.

The `echo` string deliberately avoids shell-special characters (no commas, `$`, backticks, `;`,
parentheses, or `->`) so it behaves identically under Git Bash and PowerShell.

## Keep in sync

`docs/prompting-best-practices-for-developers.md` is the source of truth. The other files are
derived from it — if you change the rules in the doc, update:

- `CLAUDE.md` (the 6 rules + explanations)
- the `echo` checklist in `.claude/settings.json`
- `.claude/skills/writing-tests/SKILL.md` and `.claude/commands/bug-review.md`

## Note on limits

This is a **soft** gate: the hook injects a reminder and Claude enforces it on itself — a developer
can still force the original prompt (e.g. by saying "just do it"). Skills are model-invoked, so the
`writing-tests` rules load on a best-effort basis, not guaranteed every time.

For true enforcement, a `UserPromptSubmit` hook can also **hard-block** a prompt: exit code `2` with
a message on stderr stops the prompt from reaching Claude. That requires a small script instead of a
plain `echo` (and a way to decide when to block) — out of scope for this bundle, but a natural next
step if you want a real gate rather than a reminder.
