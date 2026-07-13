#!/usr/bin/env sh
# PreToolUse(Read) hook — deny whole-file reads of large files (no offset/limit).
# Encourages targeted reads (offset/limit) or a grep-first workflow.
# Threshold: > 1500 lines. Reads with offset OR limit set are always allowed.
# Needs `jq`; if absent, allows (fails open).

input=$(cat)
command -v jq >/dev/null 2>&1 || exit 0

file=$(printf '%s' "$input"  | jq -r '.tool_input.file_path // ""')
offset=$(printf '%s' "$input" | jq -r '.tool_input.offset // empty')
limit=$(printf '%s' "$input"  | jq -r '.tool_input.limit // empty')

# Targeted read already requested -> allow.
[ -n "$offset" ] && exit 0
[ -n "$limit" ]  && exit 0
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0

lines=$(wc -l < "$file" 2>/dev/null | tr -d ' ')
if [ -n "$lines" ] && [ "$lines" -gt 1500 ]; then
  jq -cn --arg r "'$file' is ${lines} lines — reading it whole burns context. Grep to the relevant symbol first, then Read with offset/limit around it." \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
fi

exit 0
