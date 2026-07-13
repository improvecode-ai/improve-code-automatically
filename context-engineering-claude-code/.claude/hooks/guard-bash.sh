#!/usr/bin/env sh
# PreToolUse(Bash) hook — Balanced mode: deny only CLEAR token waste, let everything else through.
# Denies:  recursive `grep -r/-R` over the tree  (use rg)
#          `cat`/`type` of a large file          (filter first: rg/head/tail)
# Does NOT touch normal `grep` in pipelines (e.g. `git log | grep fix`).
# Emits PreToolUse permissionDecision JSON. Needs `jq`; if absent, allows (fails open).

input=$(cat)

deny() {
  # Emit deny JSON. Use jq when available; else hand-build (reason here is fixed/safe text).
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg r "$1" \
      '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  else
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  fi
  exit 0
}

if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
else
  # jq-free fallback: still catch the headline case (recursive grep) by scanning raw input.
  case "$input" in
    *grep\ -r*|*grep\ -R*|*grep\ -*r*|*grep\ -*R*)
      deny "Use 'rg' instead of recursive grep — faster, respects .gitignore, less output into context." ;;
  esac
  exit 0
fi

# Recursive grep over the tree -> ripgrep is faster and respects .gitignore.
case "$cmd" in
  *grep\ -r*|*grep\ -R*|*grep\ -*r*|*grep\ -*R*)
    deny "Use 'rg' instead of recursive grep — faster, respects .gitignore, less output into context."
    ;;
esac

# cat/type of a large file (> ~800 lines) -> filter before it enters context.
target=$(printf '%s' "$cmd" | sed -n 's/^[[:space:]]*\(cat\|type\)[[:space:]]\{1,\}\([^|;&>]*\).*/\2/p' | awk '{print $1}')
if [ -n "$target" ] && [ -f "$target" ]; then
  wc_lines=$(wc -l < "$target" 2>/dev/null | tr -d ' ')
  if [ -n "$wc_lines" ] && [ "$wc_lines" -gt 800 ]; then
    deny "'$target' is ${wc_lines} lines — don't cat it whole. Filter first (rg PATTERN, head/tail, or a script that returns only the answer)."
  fi
fi

exit 0
