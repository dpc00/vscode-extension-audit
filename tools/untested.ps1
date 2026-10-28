param(
  [int]$Skip = 0,
  [int]$Count = 8,
  [string]$TestedFile = "$PSScriptRoot\..\RESULTS.tsv",
  [string]$ListFile = "$PSScriptRoot\..\lists\audit_list_2026_10_28_top300.tsv"
)
# Lists the next untested rows of an audit list, starting after $Skip rows.
# $ListFile: tab-separated with a header row, column 1 = order, column 3 = pkg (extension id), column 6 = name.
# $TestedFile: RESULTS.tsv, column 1 = extension id (compared case-insensitively).
$set = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($l in (Get-Content $TestedFile | Select-Object -Skip 1)) { [void]$set.Add(($l -split "`t")[0].ToLower()) }
$i = $Skip; $found = 0
foreach ($line in (Get-Content $ListFile | Select-Object -Skip 1 | Select-Object -Skip $Skip)) {
  $i++
  $c = $line -split "`t"
  if (-not $set.Contains($c[2].ToLower())) {
    "$i | $($c[0]) | $($c[2]) | $($c[5])"
    $found++
    if ($found -ge $Count) { break }
  }
}