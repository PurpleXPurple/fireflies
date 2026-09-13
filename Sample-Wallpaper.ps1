Add-Type -AssemblyName System.Drawing
$wp = (Get-ItemProperty 'HKCU:\Control Panel\Desktop').Wallpaper
if (-not (Test-Path $wp)) { exit }
$img = [System.Drawing.Bitmap]::FromFile($wp)
$small = New-Object System.Drawing.Bitmap $img, 32, 18

$colors = New-Object System.Collections.ArrayList
for ($y=0; $y -lt 18; $y++) {
  for ($x=0; $x -lt 32; $x++) {
    $c = $small.GetPixel($x,$y)
    $max = [Math]::Max($c.R, [Math]::Max($c.G, $c.B))
    $min = [Math]::Min($c.R, [Math]::Min($c.G, $c.B))
    $lum = $c.R*0.299 + $c.G*0.587 + $c.B*0.114
    if ($lum -lt 30 -or $lum -gt 230) { continue }
    $sat = if ($max -gt 0) { ($max - $min) / $max } else { 0 }
    [void]$colors.Add([PSCustomObject]@{ R=$c.R; G=$c.G; B=$c.B; Score=$sat*$lum })
  }
}

if ($colors.Count -eq 0) {
  $r=210; $g=180; $b=130
} else {
  $top = $colors | Sort-Object Score -Descending | Select-Object -First 20
  $r = [int](($top | Measure-Object R -Average).Average)
  $g = [int](($top | Measure-Object G -Average).Average)
  $b = [int](($top | Measure-Object B -Average).Average)
}

$r = [Math]::Min(255, [int]($r*1.35))
$g = [Math]::Min(255, [int]($g*1.35))
$b = [Math]::Min(255, [int]($b*1.35))
$hr = [Math]::Min(255, $r+60)
$hg = [Math]::Min(255, $g+60)
$hb = [Math]::Min(255, $b+60)

$out = "[Variables]`r`nFFColor=$r,$g,$b`r`nFFCore=$hr,$hg,$hb`r`n"
[System.IO.File]::WriteAllText("$PSScriptRoot\wallpaper-vars.inc", $out)
$img.Dispose(); $small.Dispose()