# أدوات المشروع: bump_version.ps1
# يرفع إصدار التطبيق في pubspec.yaml وفق سيمفير:
#   .\tools\bump_version.ps1            -> 1.0.2+3  (patch +1, build +1)
#   .\tools\bump_version.ps1 -Minor     -> 1.1.0+3  (minor +1, patch=0, build +1)
#   .\tools\bump_version.ps1 -Major     -> 2.0.0+3
#   .\tools\bump_version.ps1 -Set 1.2.0 -Build 7
param(
  [switch]$Minor,
  [switch]$Major,
  [string]$Set,
  [int]$Build = -1
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pubspec = Join-Path $root 'pubspec.yaml'
$t = [IO.File]::ReadAllText($pubspec)
$m = [regex]::Match($t, '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)')
if (-not $m.Success) { throw 'لم أجد سطر version في pubspec.yaml' }
$majorN = [int]$m.Groups[1].Value; $minorN = [int]$m.Groups[2].Value
$patchN = [int]$m.Groups[3].Value; $buildN = [int]$m.Groups[4].Value

if ($Set) {
  $sm = [regex]::Match($Set.Trim(), '^(\d+)\.(\d+)\.(\d+)$')
  if (-not $sm.Success) { throw '-Set يجب أن يكون مثل 1.2.0' }
  $majorN = [int]$sm.Groups[1].Value; $minorN = [int]$sm.Groups[2].Value; $patchN = [int]$sm.Groups[3].Value
} elseif ($Major) { $majorN++; $minorN = 0; $patchN = 0 }
elseif ($Minor) { $minorN++; $patchN = 0 }
else { $patchN++ }

if ($Build -ge 0) { $buildN = $Build } else { $buildN++ }
$new = "version: $majorN.$minorN.$patchN+$buildN"
$t = $t.Remove($m.Index, $m.Length).Insert($m.Index, $new)
[IO.File]::WriteAllText($pubspec, $t)
Write-Host "NEW VERSION -> $majorN.$minorN.$patchN (build $buildN)"
Write-Host 'TIP: بعد البناء ارفع الـAPK ثم انشر رقم/بناء/رابط الإصدار من لوحة التحكم ← إصدار التطبيق.'
