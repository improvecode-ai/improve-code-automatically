# PreToolUse(Read) hook (PowerShell) — deny whole-file reads of large files (> 1500 lines, no offset/limit).
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
try { $ti = ($raw | ConvertFrom-Json).tool_input } catch { exit 0 }

if ($ti.offset) { exit 0 }
if ($ti.limit)  { exit 0 }
$file = $ti.file_path
if (-not $file) { exit 0 }
if (-not (Test-Path $file -PathType Leaf)) { exit 0 }

$n = (Get-Content $file | Measure-Object -Line).Lines
if ($n -gt 1500) {
  @{ hookSpecificOutput = @{
      hookEventName            = 'PreToolUse'
      permissionDecision       = 'deny'
      permissionDecisionReason = "'$file' is $n lines - reading it whole burns context. Grep to the relevant symbol first, then Read with offset/limit around it."
  } } | ConvertTo-Json -Compress -Depth 5
}
exit 0
