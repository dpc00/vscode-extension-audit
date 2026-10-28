# Rebuilds ISSUES.tsv (repo root) from GitHub: every issue we filed, with current state.
# Columns match sublime-package-audit's ISSUES.tsv: repository, number, title, state, created, closed, url, logged_title, checked, kind
# Usage: tools\issues_tsv.ps1   (needs gh, logged in as the account that filed the issues)
$issues = @(
    'NilsJPWerner/autoDocstring#315', 'cschlosser/doxdocgen#349', 'cschlosser/doxdocgen#350', 'cschlosser/doxdocgen#351',
    'kbrose/vsc-python-indent#135', 'oderwat/vscode-indent-rainbow#208', 'HansUXdev/B5-Snippets#18',
    'fivethree-team/vscode-ionic-snippets#32', 'streetsidesoftware/vscode-spell-checker#5602', 'streetsidesoftware/vscode-spell-checker#5603', 'yzhang-gh/vscode-markdown#1592', 'yzhang-gh/vscode-markdown#1593', 'prettier/prettier-vscode#4015', 'tamasfe/taplo#894'
)
$out = New-Object System.Collections.Generic.List[string]
$out.Add("repository`tnumber`ttitle`tstate`tcreated`tclosed`turl`tlogged_title`tchecked`tkind")
$today = Get-Date -Format 'yyyy-MM-dd'
foreach ($i in $issues) {
    $repo, $num = $i -split '#'
    $j = gh api "repos/$repo/issues/$num" | ConvertFrom-Json
    $closed = if ($j.closed_at) { $j.closed_at.Substring(0, 10) } else { '' }
    $title = ($j.title -replace "[`t`r`n]+", ' ')
    $out.Add(("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t`t{7}`tissue" -f $repo, $num, $title, $j.state, $j.created_at.Substring(0, 10), $closed, $j.html_url, $today))
}
[IO.File]::WriteAllLines((Join-Path (Split-Path $PSScriptRoot -Parent) 'ISSUES.tsv'), $out, (New-Object Text.UTF8Encoding($false)))
Write-Output "ISSUES.tsv: $($issues.Count) issues"
