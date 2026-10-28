# Static triage of one extension: downloads the .vsix, unpacks it into a fresh folder under -WorkRoot and READS it.
# Nothing from the extension is run. Usage: powershell -File tools\triage.ps1 -Id esbenp.prettier-vscode -WorkRoot <folder>
param(
    [Parameter(Mandatory)][string]$Id,
    [Parameter(Mandatory)][string]$WorkRoot,
    [string]$Version = 'latest'   # "latest" can be a pre-release the installer will not pick: check list_extensions/install output and pass that version
)
$ErrorActionPreference = 'Stop'
$pub, $name = $Id.Split('.', 2)
$dir = Join-Path $WorkRoot ($Id.ToLower())
if (Test-Path $dir) { throw "folder exists: $dir" }
New-Item -ItemType Directory -Path $dir | Out-Null
$vsix = Join-Path $dir 'ext.vsix'
$url = "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$pub/vsextensions/$name/$Version/vspackage"
curl.exe -s -L --compressed -o $vsix $url
if (-not (Test-Path $vsix) -or (Get-Item $vsix).Length -lt 1000) { throw "download failed for $Id" }
$hash = (Get-FileHash $vsix -Algorithm SHA256).Hash
$x = Join-Path $dir 'x'
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($vsix, $x)
$pkgPath = Join-Path $x 'extension\package.json'
$pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
"ID: $Id  version: $($pkg.version)  publisher: $($pkg.publisher)  size: $((Get-Item $vsix).Length) bytes"
"SHA256: $hash"
"main: $($pkg.main)   browser: $($pkg.browser)"
"activationEvents: $(@($pkg.activationEvents) -join ', ')"
"extensionDependencies: $(@($pkg.extensionDependencies) -join ', ')   extensionPack: $(@($pkg.extensionPack) -join ', ')"
"scripts: $(@($pkg.scripts.PSObject.Properties.Name | Where-Object { $_ -match 'install|postinstall|preinstall' }) -join ', ')"
"capabilities.untrustedWorkspaces: $($pkg.capabilities.untrustedWorkspaces.supported)   virtualWorkspaces: $($pkg.capabilities.virtualWorkspaces)"
"binaries/native in package:"
Get-ChildItem $x -Recurse -File | Where-Object { $_.Extension -in '.exe', '.dll', '.node', '.so', '.dylib', '.bat', '.cmd', '.ps1', '.sh', '.vbs' } | ForEach-Object { '  ' + $_.FullName.Substring($x.Length) + ' ' + $_.Length }
$all = Get-ChildItem $x -Recurse -File | Where-Object { $_.Extension -in '.js', '.cjs', '.mjs' }
$js = $all | Where-Object { $_.FullName -notmatch '\\node_modules\\' }
$deps = $all | Where-Object { $_.FullName -match '\\node_modules\\' }
"js files: own $($js.Count) ($(($js | Measure-Object Length -Sum).Sum) bytes), bundled node_modules $($deps.Count) ($(($deps | Measure-Object Length -Sum).Sum) bytes); the patterns below look at OWN code only"
"bundled top-level packages: $((Get-ChildItem (Join-Path $x 'extension\node_modules') -Directory -ErrorAction SilentlyContinue | Select-Object -First 400 | Measure-Object).Count)"
"own js files: $(($js | ForEach-Object { $_.FullName.Substring($x.Length) } | Select-Object -First 25) -join '; ')"
$patterns = 'child_process','\beval\(','new Function\(','XMLHttpRequest','https?://[A-Za-z0-9._-]+','atob\(|fromCharCode|base64','process\.env','os\.homedir|\.ssh|\.aws|credentials','require\(.https?.\)|fetch\('
foreach ($p in $patterns) {
    $n = 0; $files = @()
    foreach ($f in $js) { $c = (Select-String -Path $f.FullName -Pattern $p -AllMatches -ErrorAction SilentlyContinue | Measure-Object).Count; if ($c) { $n += $c; $files += $f.Name } }
    "pattern [$p]: $n hits in $($files.Count) files  e.g. $((($files | Select-Object -Unique -First 4)) -join ', ')"
}
"hosts contacted (distinct, from js):"
$js | ForEach-Object { Select-String -Path $_.FullName -Pattern 'https?://([A-Za-z0-9._-]+)' -AllMatches -ErrorAction SilentlyContinue } | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value.ToLower() } | Group-Object | Sort-Object Count -Descending | Select-Object -First 25 | ForEach-Object { '  ' + $_.Name + ' x' + $_.Count }
