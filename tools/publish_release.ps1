# أدوات المشروع: publish_release.ps1
# دورة إصدار كاملة لأندرويد: يرفع الرقم، يبني APK + ويب، يضع الـAPK داخل
# مجلد الاستضافة download/ ثم ينشر الويب — فلا يعود الرابط يفتح التطبيق.
#
#   .\tools\publish_release.ps1            # باتش تلقائي (1.0.2+2 …)
#   .\tools\publish_release.ps1 -Minor     # قفزة 1.1.0
#   .\tools\publish_release.ps1 -NoDeploy  # بناء فقط بلا نشر
param(
  [switch]$Minor,
  [switch]$Major,
  [switch]$NoDeploy
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host '── 1) رفع رقم الإصدار…' -ForegroundColor Cyan
if ($Major) { & "$PSScriptRoot\bump_version.ps1" -Major }
elseif ($Minor) { & "$PSScriptRoot\bump_version.ps1" -Minor }
else { & "$PSScriptRoot\bump_version.ps1" }
$versionLine = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(.+)\+(.+)$').Matches[0]
$ver = $versionLine.Groups[1].Value
$build = $versionLine.Groups[2].Value
Write-Host "   الإصدار الجديد: $ver (build $build)"

Write-Host '── 2) بناء APK إصدار…' -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { throw 'فشل بناء الـAPK' }
$apk = 'build\app\outputs\flutter-apk\app-release.apk'

Write-Host '── 3) بناء الويب…' -ForegroundColor Cyan
flutter build web --release
if ($LASTEXITCODE -ne 0) { throw 'فشل بناء الويب' }

Write-Host '── 4) نسخ الـAPK إلى download/ داخل الويب…' -ForegroundColor Cyan
New-Item -ItemType Directory -Force 'build\web\download' | Out-Null
Copy-Item $apk 'build\web\download\qarity.apk' -Force
$mb = [math]::Round((Get-Item 'build\web\download\qarity.apk').Length / 1MB, 1)
Write-Host "   qarity.apk ($mb MB) جاهز خلف https://abudshisha.web.app/download/qarity.apk"

if (-not $NoDeploy) {
  Write-Host '── 5) نشر الاستضافة…' -ForegroundColor Cyan
  firebase deploy --only hosting
  if ($LASTEXITCODE -ne 0) { throw 'فشل النشر' }
  Write-Host ''
  Write-Host '✅ نُشر. الخطوة الأخيرة (يدوية، 30 ثانية):' -ForegroundColor Green
  Write-Host "   افتح لوحة التحكم ← النظرة العامة ← بطاقة «إصدار التطبيق» واضبط:"
  Write-Host "     رقم الإصدار الظاهر : $ver"
  Write-Host "     رقم البناء build   : $build"
  Write-Host "     الحد الأدنى min    : 1  (ارفعه لرقم هذا البناء إن أردت إجبار الجميع)"
  Write-Host "     الرابط             : https://abudshisha.web.app/download/qarity.apk"
  Write-Host '   ثم «نشر بيانات الإصدار». عندها فقط يرى الأهالي التنبيه ويُفهم زر التنزيل.'
} else {
  Write-Host '   (تخطيت النشر بأمر -NoDeploy)' -ForegroundColor Yellow
}
