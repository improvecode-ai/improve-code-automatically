# UserPromptSubmit hook (PowerShell). Fires on EVERY prompt.
# Injects a one-line guardrail pointer + a lightweight prompt-quality nudge. Never blocks.
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
$prompt = ''
try { $prompt = ($raw | ConvertFrom-Json).prompt } catch { $prompt = '' }

$lines = ($prompt -split "`n").Count
$words = ($prompt -split '\s+' | Where-Object { $_ -ne '' }).Count

$nudge = ''
if ($lines -gt 50) {
  $nudge = "Large paste detected ($lines lines): filter it first (rg/head/script) and pass only the relevant slice - see 'Think in code'. "
} elseif ($words -gt 0 -and $words -le 3) {
  $nudge = "Very short prompt: add what you need + what it's for + desired output format to avoid a correction round. "
}

$reminder = "Context-engineering guardrails active (see CLAUDE.md): answer-first/concise; caveman only for simple tasks; delegate search/lookups to the explore-haiku subagent; read ranges not whole files; rg over grep; think-in-code for large data; watch the context bar for /compact."

$out = @{
  hookSpecificOutput = @{
    hookEventName    = 'UserPromptSubmit'
    additionalContext = "$nudge$reminder"
  }
}
$out | ConvertTo-Json -Compress -Depth 5
exit 0
