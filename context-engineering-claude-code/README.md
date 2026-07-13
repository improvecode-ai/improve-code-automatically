# Context Engineering bundle for Claude Code

A drop-in bundle that pushes Claude Code toward token-saving / context-engineering best practices — and,
unlike the Copilot sibling bundle, actually **forces** the ones that can be forced instead of only
suggesting them.

It is the Claude Code counterpart to `../context-engineering-copilot/`. Same goals (model selection,
conciseness, think-in-code, targeted references, CLI-over-MCP, session hygiene, a prompt-quality gate),
but built on Claude Code's real enforcement surfaces.

## Why this is stronger than the Copilot version

| Capability | Copilot | This bundle |
|------------|---------|-------------|
| Best-practice check on **every** prompt | model had to remember (~70%) | `UserPromptSubmit` hook, deterministic (~100%) |
| Real context-window % | no access (guessed) | live in the statusline |
| Block raw file/log dumps | suggestion | `PreToolUse` hooks **deny** them |
| Cheap model for search/lookups | not possible | `explore-haiku` (Haiku) subagent |

Full honest breakdown — including what still **can't** be forced — is in
[`context-engineering-rules-explained.md`](./context-engineering-rules-explained.md).

## What's in here

```
context-engineering-claude-code/
├── README.md                              # you are here
├── CLAUDE.md                              # the guardrails (soft rules) — copy into target repo root
├── prompt-quality-evaluator.md            # the 6-mistakes gate + how to make it a real hook
├── context-engineering-rules-explained.md # feasibility map: rule -> mechanism -> forced?
└── .claude/                               # copy into the target repo's .claude/
    ├── settings.json                      # bash / Git Bash variant (default)
    ├── settings.windows.json              # PowerShell variant (Windows without Git Bash)
    ├── statusline.sh / .ps1               # [model]  ##### NN% ctx  |  $cost
    ├── agents/explore-haiku.md            # cheap Haiku subagent for search/lookups/tests
    └── hooks/
        ├── prompt-check.sh / .ps1         # UserPromptSubmit: always-on reminder + quality nudge
        ├── guard-bash.sh / .ps1           # PreToolUse(Bash): deny recursive grep / cat of big files
        └── guard-read.sh / .ps1           # PreToolUse(Read): deny whole-file reads of large files
```

## Prerequisites

- **Claude Code** (recent version — statusline `context_window` fields need v2.1.132+).
- **bash variant** (`settings.json`): needs `jq` on PATH. On macOS/Linux it usually is; on Windows the
  hooks run under Git Bash if installed. Without `jq` the scripts **fail open** (allow) so nothing
  breaks — but the deny-guards go quiet (except recursive-grep, which has a jq-free fallback).
- **PowerShell variant** (`settings.windows.json`): **no external dependency** — uses built-in
  `ConvertFrom-Json`. Recommended on Windows machines without Git Bash / jq.

## Install (into any repo)

1. Copy `CLAUDE.md` to the **target repo root**. If the repo already has a `CLAUDE.md`, paste the rule
   sections in rather than overwriting.
2. Copy the `.claude/` folder into the target repo (merge if `.claude/` already exists).
3. Pick your shell variant:
   - **bash / Git Bash / macOS / Linux:** keep `settings.json` as is.
   - **Windows without Git Bash:** delete `settings.json` and rename `settings.windows.json` →
     `settings.json` (or merge its `hooks` + `statusLine` blocks into your existing one).
4. If the repo already has a `.claude/settings.json`, **merge** the `statusLine` and `hooks` keys into it
   rather than replacing the whole file (other settings — permissions, env — must be preserved).
5. Restart Claude Code in the repo. The statusline appears at the bottom; hooks fire on the next prompt.

> Paths use `${CLAUDE_PROJECT_DIR}`, so no editing is needed after copying — they resolve to the repo
> root wherever the bundle lands.

### Personal (all your projects) instead of per-repo
Put the same `hooks` / `statusLine` blocks and scripts under `~/.claude/` instead of the project
`.claude/`. Project settings and personal settings both apply; project-level is best for team sharing.

## Verify it works

Run `claude --debug-file /tmp/cc.log` in a repo where you installed it, then:

1. Submit any prompt → the `UserPromptSubmit` reminder is injected (check the debug log / that replies
   stay concise).
2. Ask Claude to run `grep -r foo .` → **denied** ("use rg"). Ask `git log --oneline | grep fix` →
   **allowed** (normal pipeline, not blocked).
3. Ask Claude to Read a >1500-line file whole → **denied** with an offset/limit suggestion.
4. Watch the statusline show `[model]  #####----- NN% ctx  |  $cost`; the % rises as context grows and
   warns past 70%.
5. Ask a "where is X defined?" question → it should be delegated to the `explore-haiku` (Haiku) subagent.

You can smoke-test the scripts directly without Claude:
```sh
echo '{"tool_input":{"command":"grep -r foo ."}}' | sh .claude/hooks/guard-bash.sh   # -> deny JSON
echo '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":42},"cost":{"total_cost_usd":0.01}}' \
  | sh .claude/statusline.sh                                                          # -> status string
```
(PowerShell: pipe the same JSON into `powershell -NoProfile -File .claude\hooks\guard-bash.ps1`.)

## Tuning

- **Thresholds:** big-file line limits live at the top of `guard-bash` (800) and `guard-read` (1500);
  the `/compact` warning at 70% is in `statusline`. Adjust to taste.
- **Stricter or softer:** this ships in **Balanced** mode (inject always; deny only clear waste). To go
  softer, remove the `PreToolUse` entries from `settings.json` (keep only the reminder). To go stricter,
  add more `PreToolUse` matchers (e.g. deny specific `mcp__*` tools).
- **Real semantic prompt gate:** swap the heuristic for the `type: "prompt"` hook in
  [`prompt-quality-evaluator.md`](./prompt-quality-evaluator.md) (costs one Haiku call per prompt).

## Known limits (by design, documented honestly)

- Hooks can't read the **current session model**, so "you're on Opus for a trivial task" is surfaced in
  the statusline but not auto-blocked.
- Nothing can **auto-run `/compact`** at a threshold — the statusline warns, you act.
- Output compression is a before-the-fact convention (think-in-code / `PreToolUse` rewrite), not a
  magic post-filter — `PostToolUse` runs after the output is already in context.

See [`context-engineering-rules-explained.md`](./context-engineering-rules-explained.md) for the
per-rule reasoning.
