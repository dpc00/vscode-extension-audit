# Builds a list of VS Code Marketplace extensions sorted by install count (reads data outside VS Code only).
# Usage: powershell -File tools\list_extensions.ps1 -Pages 3 -Out lists\audit_list_2026_10_28_top300.tsv
param(
    [int]$Pages = 3,
    [string]$Out = (Join-Path $PSScriptRoot '..\lists\audit_list.tsv')
)
$ErrorActionPreference = 'Stop'
$uri = 'https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery'
$headers = @{ 'Accept' = 'application/json;api-version=7.1-preview.1'; 'Content-Type' = 'application/json' }
$rows = @('order' + "`t" + 'installs' + "`t" + 'pkg' + "`t" + 'version' + "`t" + 'last_updated' + "`t" + 'name')
$rank = 0
for ($page = 1; $page -le $Pages; $page++) {
    $body = @{
        filters    = @(@{
            criteria   = @(@{ filterType = 8; value = 'Microsoft.VisualStudio.Code' })
            pageNumber = $page
            pageSize   = 100
            sortBy     = 4
            sortOrder  = 0
        })
        assetTypes = @()
        flags      = 914
    } | ConvertTo-Json -Depth 6
    $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
    foreach ($e in $resp.results[0].extensions) {
        $rank++
        $installs = ($e.statistics | Where-Object { $_.statisticName -eq 'install' }).value
        $ver = $e.versions[0].version
        $upd = $e.versions[0].lastUpdated
        $rows += ("{0}`t{1}`t{2}.{3}`t{4}`t{5}`t{6}" -f $rank, [int64]$installs, $e.publisher.publisherName, $e.extensionName, $ver, $upd, $e.displayName)
    }
}
$rows | Set-Content -Path $Out -Encoding utf8
"wrote $($rows.Count - 1) rows to $Out"
