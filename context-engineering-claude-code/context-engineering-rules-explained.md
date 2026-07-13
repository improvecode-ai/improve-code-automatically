# Rules explained — does it actually work for Claude Code?

The Copilot bundle honestly admitted its ceiling: every rule lived in an instructions file the model
**chose** to follow (~70% of the time), and anything needing runtime data (real context %, timestamps,
forcing a model switch) was downgraded to "informational only" because Copilot has no access.

Claude Code raises that ceiling because it has three things Copilot doesn't: **hooks** (deterministic
shell commands at lifecycle events, ~100% enforcement), a **statusline** (real session telemetry), and
**subagents** (isolated context + per-agent model). This doc maps every rule to its real enforcement
level here — and is equally honest about what still can't be forced.

Legend:
- ✅ **FORCED** — a hook/config makes it happen deterministically; not model goodwill.
- 🟢 **MEASURED/VISIBLE** — real runtime data is surfaced (statusline), but not auto-enforced.
- ⚠️ **SOFT** — lives in `CLAUDE.md`; model applies by judgment (like Copilot).
- 💲 **FORCED-BUT-COSTS** — enforceable, but spends a model call.

---

## 1. Always-triggered check (Copilot RULE #0)
**Copilot:** ⚠️ model had to remember to print the block. **Claude Code:** ✅ FORCED **injection**.
`UserPromptSubmit` runs `prompt-check` on **every** prompt and injects `additionalContext` — the
trigger is the harness, not the model's memory. That's exactly the user's "must always be triggered"
requirement, and it is genuinely guaranteed.
**Honest limit:** the *injection* is forced; whether the model then produces a perfectly calibrated
answer is still soft. And the injected text is itself input tokens every turn — so we inject a **single
short line** (a pointer to the cached `CLAUDE.md`), not the whole rule block. Injecting the full block
each turn would be uncached bloat working against the goal — a mistake caught during this bundle's own
review.
**Test:** submit any prompt with `claude --debug-file /tmp/cc.log`; confirm the pointer appears and the
per-turn input token count doesn't balloon.

## 2. Model selection
**Copilot:** could suggest a model and even warn "switch to Opus" (⚠️, model-judged).
**Claude Code:** split verdict.
- Routing cheap work to Haiku → ✅ FORCED, via `agents/explore-haiku.md` (`model: haiku`). Delegated
  search/lookups genuinely run on Haiku in isolated context.
- "You're on Opus for a trivial task, switch down" → **cannot be hard-enforced.** Hooks receive
  `session_id`, `cwd`, `prompt` on stdin — **not the current model name.** So no hook can branch on
  "is this Opus?". The model *is* in the statusline (`model.display_name`), so it's 🟢 VISIBLE, but a
  statusline only displays; it can't block. Net: model choice is surfaced + advised, not forced.
**Test:** ask a search question → confirm it's delegated to `explore-haiku`. Check the statusline shows
the session model.

## 3. Conciseness
**Copilot:** ✅ (soft, with an "unless relevant" escape hatch). **Claude Code:** ⚠️ SOFT — same nature,
lives in `CLAUDE.md`. Hooks can't measure "was this reply concise", so this stays model-applied. Biggest
single output-token saver (~60-80% on typical tasks) but fundamentally a style instruction.

## 4. Caveman style (simple tasks only)
⚠️ SOFT, conditional on the model classifying the task correctly — identical caveat to Copilot. No hook
can know "is this task simple" better than the model. Kept as-is.

## 5. Session hygiene (/compact, /clear)
**Copilot:** ⚠️ guessed session length. **Claude Code:** 🟢 MEASURED. The statusline shows the **real**
`context_window.used_percentage` and prints `! /compact soon` past 70%. This is the rule Copilot most
wanted and couldn't have.
**Honest limit:** it's a **visible signal**, not an auto-action. No hook input carries live context-%,
so nothing can *force* `/compact` at a threshold — you still run it. `used_percentage` is input-tokens
only and is `null` early in a session and right after `/compact` (the scripts `// 0`-guard that).

## 6. Think in code (don't dump raw data)
**Copilot:** ✅ suggestion only. **Claude Code:** ✅ FORCED for the worst cases + ⚠️ SOFT otherwise.
- `guard-bash` denies `cat`/`type` of a large file and recursive `grep` (→ rg). ✅ FORCED.
- The general habit (write a filtering script, pipe before it enters context) stays ⚠️ SOFT in
  `CLAUDE.md`.
**Honest limit on "compress output automatically":** a `PostToolUse` hook fires **after** the tool ran,
so it can't shrink output that was already captured into context. Real compression must happen
**before**: either a `PreToolUse` `updatedInput` rewrite that appends `| tail`/a filter, or the
think-in-code habit. Only one hook should rewrite a given tool's input — if several do, the last to
finish wins (non-deterministic per the docs). We therefore document the rewrite pattern rather than ship
a fragile auto-compressor.
**Test:** ask Claude to `cat` a 1000-line file → denied with a filter suggestion.

## 7. Targeted references (ranges, not whole files)
**Copilot:** ⚠️ mostly advice to the user. **Claude Code:** ✅ FORCED. `guard-read` denies a `Read`
with no `offset`/`limit` on a file over ~1500 lines, telling Claude to grep-then-range. This is a real
tool-level block, not a suggestion.
**Test:** ask to Read a large file whole → denied; a ranged read passes.

## 8. CLI over MCP
⚠️ SOFT (in `CLAUDE.md`). A hook *could* deny specific `mcp__*` tools via a `PreToolUse` matcher, but
that's project-specific and heavy-handed, so the bundle leaves it as guidance. The one concrete forced
piece — prefer `rg` over recursive `grep` — is handled by `guard-bash` (✅).

## 9. Input efficiency (umbrella)
Parent rule for #6/#7. Its two sharp edges (big Read, big cat / recursive grep) are ✅ FORCED by the
guards; the general "read the minimum" disposition is ⚠️ SOFT.

## 10. Prompt-quality gate (the 6 mistakes)
**Copilot:** paste-and-hope. **Claude Code:** ✅ triggered every prompt, at a quality you choose:
- Default: `prompt-check` heuristic (length/emptiness) — free, crude.
- Opt-in: a `type: "prompt"` hook — 💲 FORCED-BUT-COSTS a Haiku call per prompt, real 6-mistake check.
See `prompt-quality-evaluator.md`.

---

## Summary

| Rule | Copilot | Claude Code | Level |
|------|---------|-------------|-------|
| Always-triggered check | ⚠️ memory | `UserPromptSubmit` injects every turn | ✅ FORCED injection |
| Route cheap work to Haiku | ❌ | `explore-haiku` subagent | ✅ FORCED |
| "Switch down from Opus" | ⚠️ | statusline shows model; hook can't read it | 🟢 VISIBLE only |
| Real context % / /compact | ❌ no access | statusline `used_percentage` + warn | 🟢 MEASURED (not auto) |
| Block whole-file Read | ⚠️ | `guard-read` deny | ✅ FORCED |
| Block cat-big / recursive grep | ⚠️ | `guard-bash` deny | ✅ FORCED |
| Prompt-quality gate | paste | heuristic hook / prompt hook | ✅ / 💲 |
| Conciseness, Caveman, CLI>MCP | ✅/⚠️ | `CLAUDE.md` | ⚠️ SOFT |

**Bottom line:** Claude Code moves the "always triggered" requirement and the file/log-dump guards from
*suggestion* to *forced*, and turns Copilot's impossible "real context %" into a live measurement. What
still can't be forced: acting on the current session model (hooks are blind to it), auto-running
`/compact` at a threshold, and judgment-based style rules — those remain visible signals or soft
guidance. That honesty is the point: the bundle forces what can be forced and is explicit about the
rest, rather than pretending.
