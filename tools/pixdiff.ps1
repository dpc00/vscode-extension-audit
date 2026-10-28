param(
    [Parameter(Mandatory = $true)][string]$A,
    [Parameter(Mandatory = $true)][string]$B
)
# Compares two window captures and reports how many pixels changed and where, so a binding whose
# only effect is DOM state (toggle outputs, line numbers, find widget) can be verified without a
# reader looking at the image. Any channel differing by more than 8 counts as a change.
Add-Type -AssemblyName System.Drawing
$ia = [System.Drawing.Bitmap]::FromFile($A)
$ib = [System.Drawing.Bitmap]::FromFile($B)
if ($ia.Width -ne $ib.Width -or $ia.Height -ne $ib.Height) {
    "size mismatch: $($ia.Width)x$($ia.Height) vs $($ib.Width)x$($ib.Height)"
    exit 2
}
$rect = New-Object System.Drawing.Rectangle 0, 0, $ia.Width, $ia.Height
$da = $ia.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$db = $ib.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$len = [Math]::Abs($da.Stride) * $ia.Height
$bufA = New-Object byte[] $len
$bufB = New-Object byte[] $len
[System.Runtime.InteropServices.Marshal]::Copy($da.Scan0, $bufA, 0, $len)
[System.Runtime.InteropServices.Marshal]::Copy($db.Scan0, $bufB, 0, $len)
$ia.UnlockBits($da)
$ib.UnlockBits($db)
$stride = [Math]::Abs($da.Stride)
$count = 0
$minX = [int]::MaxValue; $minY = [int]::MaxValue; $maxX = -1; $maxY = -1
for ($y = 0; $y -lt $ia.Height; $y++) {
    $row = $y * $stride
    for ($x = 0; $x -lt $ia.Width; $x++) {
        $i = $row + $x * 4
        $d = [Math]::Abs($bufA[$i] - $bufB[$i]) + [Math]::Abs($bufA[$i + 1] - $bufB[$i + 1]) + [Math]::Abs($bufA[$i + 2] - $bufB[$i + 2])
        if ($d -gt 8) {
            $count++
            if ($x -lt $minX) { $minX = $x }
            if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }
            if ($y -gt $maxY) { $maxY = $y }
        }
    }
}
$ia.Dispose(); $ib.Dispose()
if ($count -eq 0) {
    "changed_pixels=0 (identical)"
} else {
    "changed_pixels=$count bbox=($minX,$minY)-($maxX,$maxY)"
}
