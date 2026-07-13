# Status line (PowerShell): [model]  <bar> NN% ctx  ·  $cost   (no external deps)
$ErrorActionPreference = 'SilentlyContinue'
$raw = [Console]::In.ReadToEnd()
try { $d = $raw | ConvertFrom-Json } catch { Write-Host -NoNewline 'ctx: unavailable'; exit 0 }

$model = if ($d.model.display_name) { $d.model.display_name } else { '?' }
$pct   = [int]([math]::Floor([double]($d.context_window.used_percentage)))
$cost  = [double]$d.cost.total_cost_usd
$big   = [bool]$d.exceeds_200k_tokens

$filled = [math]::Min(10, [int]([math]::Floor($pct / 10)))
$bar = ('#' * $filled) + ('-' * (10 - $filled))

$flag = if ($big) { ' (200k+)' } else { '' }
$warn = if ($pct -ge 70) { '  ! /compact soon' } else { '' }

Write-Host -NoNewline ("[{0}] {1} {2}%{3} ctx  |  `${4:N4}{5}" -f $model, $bar, $pct, $flag, $cost, $warn)
