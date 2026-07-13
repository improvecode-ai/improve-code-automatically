#!/usr/bin/env sh
# Status line: [model]  <bar> NN% ctx  ·  $cost
# Makes context-window usage a real, always-visible signal (the thing Copilot could not measure).
# Fields per Claude Code docs: model.display_name, context_window.used_percentage (input-tokens only;
# null early / after /compact -> // 0), cost.total_cost_usd, exceeds_200k_tokens.
# Needs jq. Without jq, prints just the model-less fallback.

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf 'ctx: install jq for the context bar'
  exit 0
fi

model=$(printf '%s' "$input" | jq -r '.model.display_name // "?"')
pct=$(printf '%s'  "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
cost=$(printf '%s' "$input" | jq -r '.cost.total_cost_usd // 0')
big=$(printf '%s'  "$input" | jq -r '.exceeds_200k_tokens // false')

# 10-char bar.
filled=$(( pct / 10 ))
[ "$filled" -gt 10 ] && filled=10
bar=""
i=0
while [ "$i" -lt 10 ]; do
  if [ "$i" -lt "$filled" ]; then bar="${bar}#"; else bar="${bar}-"; fi
  i=$(( i + 1 ))
done

warn=""
[ "$pct" -ge 70 ] && warn="  ! /compact soon"
flag=""
[ "$big" = "true" ] && flag=" (200k+)"

printf '[%s] %s %s%%%s ctx  ·  $%.4f%s' "$model" "$bar" "$pct" "$flag" "$cost" "$warn"
