#!/usr/bin/env sh
# UserPromptSubmit hook. Fires on EVERY prompt (the "always triggered" check).
# - Re-points to the guardrails (one short line, NOT the full rule block -> stays cheap).
# - Adds a lightweight prompt-quality nudge (heuristic; no model call).
# Output goes to Claude as additionalContext. Never blocks (Balanced mode).
# Reads the hook JSON from stdin; needs `jq`. Degrades gracefully if jq is missing.

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  prompt=$(printf '%s' "$input" | jq -r '.prompt // ""')
else
  # No jq: skip the heuristic, still inject the pointer.
  prompt=""
fi

# --- prompt-quality heuristic (crude on purpose; the real gate is the opt-in prompt hook) ---
nudge=""
lines=$(printf '%s\n' "$prompt" | wc -l | tr -d ' ')
words=$(printf '%s' "$prompt" | wc -w | tr -d ' ')

if [ "${lines:-0}" -gt 50 ]; then
  nudge="Large paste detected (${lines} lines): filter it first (rg/head/script) and pass only the relevant slice — see 'Think in code'. "
elif [ "${words:-0}" -gt 0 ] && [ "${words:-0}" -le 3 ]; then
  nudge="Very short prompt: add what you need + what it's for + desired output format to avoid a correction round. "
fi

reminder="Context-engineering guardrails active (see CLAUDE.md): answer-first/concise; caveman only for simple tasks; delegate search/lookups to the explore-haiku subagent; read ranges not whole files; rg over grep; think-in-code for large data; watch the context bar for /compact."

# Emit as additionalContext (recommended structured form for UserPromptSubmit).
if command -v jq >/dev/null 2>&1; then
  jq -cn --arg ctx "${nudge}${reminder}" \
    '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
else
  # Fallback: plain stdout is also added to context for UserPromptSubmit.
  printf '%s%s\n' "$nudge" "$reminder"
fi

exit 0
