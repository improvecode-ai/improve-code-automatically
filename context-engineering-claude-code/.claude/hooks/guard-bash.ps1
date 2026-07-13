# PreToolUse(Bash) hook (PowerShell) — deny only CLEAR waste: recursive grep, cat of a large file.
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
try { $cmd = ($raw | ConvertFrom-Json).tool_input.command } catch { exit 0 }
if (-not $cmd) { exit 0 }

function Deny([string]$reason) {
  @{ hookSpecificOutput = @{
      hookEventName            = 'PreToolUse'
      permissionDecision       = 'deny'
      permissionDecisionReason = $reason
  } } | ConvertTo-Json -Compress -Depth 5
  exit 0
}

if ($cmd -match '\bgrep\b[^|;&]*\s-\w*[rR]') {
  Deny "Use 'rg' instead of recursive grep - faster, respects .gitignore, less output into context."
}

$m = [regex]::Match($cmd, '^\s*(cat|type)\s+([^|;&>]+)')
if ($m.Success) {
  $target = ($m.Groups[2].Value.Trim() -split '\s+')[0]
  if ($target -and (Test-Path $target -PathType Leaf)) {
    $n = (Get-Content $target | Measure-Object -Line).Lines
    if ($n -gt 800) {
      Deny "'$target' is $n lines - don't cat it whole. Filter first (rg PATTERN, head/tail, or a script that returns only the answer)."
    }
  }
}
exit 0
