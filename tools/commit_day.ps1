param([string]$Root = (Split-Path $PSScriptRoot))
# One commit per day: the first run of a day creates "Audit log through <date>", later runs that day amend it.
# Pushes with --force-with-lease because an amended commit replaces the one already pushed.
Set-Location $Root
$d = Get-Date -Format 'yyyy-MM-dd'
$subject = "Audit log through $d"
git add -A
$last = git log -1 --format=%s
if ($last -eq $subject) {
  git commit -q --amend --no-edit
} else {
  git commit -q -m $subject
}
git push -q --force-with-lease origin main
git log --oneline -2