<#
.SYNOPSIS
    Moves files and folders to the Recycle Bin, one path at a time, and says what happened.

.DESCRIPTION
    The audit rules say deletes go to the Recycle Bin, not to oblivion. This is that script.

    It uses the Windows shell's own recycle path (Microsoft.VisualBasic.FileIO.FileSystem) and
    verifies each path afterwards. When the shell refuses a path - the usual reason is a handle
    still open, e.g. the editor or a language server is holding a folder it has open, which shows
    up as "The operation was canceled" or "The system call level is not correct" - it says so and
    leaves the item alone unless -Force is given, in which case it deletes permanently.

    A folder created by an extension while VS Code is running is the common case: close the tab
    (or the window) and run the script again instead of forcing.

.PARAMETER Path
    One or more files or folders. Globs are resolved by the caller, not here.

.PARAMETER Force
    Permanently delete a path the Recycle Bin refused. Off by default.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File tools\recycle.ps1 -Path C:\tmp\probe

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File tools\recycle.ps1 -Path C:\tmp\a,C:\tmp\b -Force
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$Path,

    [switch]$Force
)

# Called through -File from cmd/bash, a comma-separated list arrives as ONE string, so split it
# here as well: -Path a,b,c and -Path a -Path b both work.
$items = New-Object System.Collections.Generic.List[string]
foreach ($entry in $Path) {
    foreach ($part in ($entry -split ',')) {
        $trimmed = $part.Trim()
        if ($trimmed) { $items.Add($trimmed) }
    }
}
if ($items.Count -eq 0) {
    Write-Output 'nothing to do: no path given'
    exit 0
}

Add-Type -AssemblyName Microsoft.VisualBasic

$failed = @()

foreach ($raw in $items) {
    try { $full = [System.IO.Path]::GetFullPath($raw) }
    catch { Write-Output "INVALID  $raw"; $failed += $raw; continue }

    if (-not (Test-Path -LiteralPath $full)) {
        Write-Output "gone     $full"
        continue
    }

    $isDir = Test-Path -LiteralPath $full -PathType Container
    $method = 'recycled'

    try {
        if ($isDir) {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($full, 'OnlyErrorDialogs', 'SendToRecycleBin')
        } else {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($full, 'OnlyErrorDialogs', 'SendToRecycleBin')
        }
    } catch {
        $reason = $_.Exception.Message

        if (-not $Force) {
            Write-Output "LOCKED   $full"
            Write-Output "         $reason"
            Write-Output "         close whatever has it open and retry, or pass -Force to delete it outright"
            $failed += $full
            continue
        }

        try {
            if ($isDir) { Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop }
            else        { Remove-Item -LiteralPath $full -Force -ErrorAction Stop }
            $method = "deleted (Recycle Bin refused: $reason)"
        } catch {
            Write-Output "FAILED   $full"
            Write-Output "         $($_.Exception.Message)"
            $failed += $full
            continue
        }
    }

    if (Test-Path -LiteralPath $full) {
        Write-Output "STILL    $full (still present after the call)"
        $failed += $full
    } else {
        Write-Output ("{0,-8} {1}" -f $method.Split(' ')[0], $full)
        if ($method -ne 'recycled') { Write-Output ("         {0}" -f ($method -replace '^deleted \(','' -replace '\)$','')) }
    }
}

if ($failed.Count -gt 0) {
    Write-Output ""
    Write-Output "$($failed.Count) path(s) not removed."
    exit 1
}

exit 0
