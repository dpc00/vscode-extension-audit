# Appends one result row to RESULTS.tsv (repo root): package, date, result, line.
# Usage: rec.ps1 -Id publisher.name -Outcome 0|1 -Note "the bugs found with issue links"
# Outcome 0: no bug found (the result column stays empty, as in sublime-package-audit). Outcome 1: the Note is written as the result.
# line = the extension's order in lists\audit_list_*_top2000.tsv when it is there. Does not commit.
param(
    [Parameter(Mandatory)][string]$Id,
    [Parameter(Mandatory)][ValidateSet('0', '1')][string]$Outcome,
    [string]$Note = ''
)
$root = Split-Path $PSScriptRoot -Parent
$file = Join-Path $root 'RESULTS.tsv'
$exists = Select-String -Path $file -Pattern ("^" + [regex]::Escape($Id) + "`t") -CaseSensitive:$false -Quiet
if ($exists) { Write-Output "already recorded: $Id (row not added)"; return }
if ($Outcome -eq '1' -and -not $Note) { throw 'outcome 1 needs -Note (the bug and its issue link)' }
$result = if ($Outcome -eq '1') { ($Note -replace "[`t`r`n]+", ' ').Trim() } else { '' }
$rank = ''
$list = Get-ChildItem (Join-Path $root 'lists') -Filter 'audit_list_*_top2000.tsv' | Select-Object -First 1
if ($list) { $m = Import-Csv $list.FullName -Delimiter "`t" | Where-Object { $_.pkg -ieq $Id } | Select-Object -First 1; if ($m) { $rank = $m.order } }
$row = "{0}`t{1}`t{2}`t{3}`n" -f $Id, (Get-Date -Format 'yyyy-MM-dd'), $result, $rank
[IO.File]::AppendAllText($file, $row, (New-Object Text.UTF8Encoding($false)))
Write-Output "recorded: $Id"