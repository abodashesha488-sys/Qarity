<#
.SYNOPSIS
    سكربت النسخ الاحتياطي التلقائي لبيانات ومجموعات قرية أبوديشيشة (Qarity).

.DESCRIPTION
    يقوم السكربت بحفظ نسخ احتياطية بصيغة JSON من المجموعات الحيوية للقرية:
    - دليل الهاتف (phone_directory)
    - الطوارئ وأرقام النجدة (emergency_contacts)
    - العيادات والمركز الطبي (medical_center_clinics, village_clinics, pharmacies)
    - دليل الخدمات والحرفيين (service_providers)
    - معلومات ومعالم القرية (village_info)
    - الأخبار، المناسبات، وسجل العزاء (news, occasions, obituaries)
    - المفقودات والإعلانات (lost_items, village_ads)

    يدعم القراءة المباشرة من Firestore REST API للمجموعات العامة أو عبر حساب الخدمة إن توفر.

.PARAMETER ProjectId
    معرّف مشروع فايربيس (افتراضيًا: abudshisha).

.PARAMETER OutDir
    مجلد حفظ النسخ الاحتياطية (افتراضيًا: backups).

.PARAMETER Zip
    ضغط مجلد النسخة الاحتياطية في ملف ZIP مضغوط بعد الانتهاء.

.EXAMPLE
    .\scripts\backup_village_data.ps1
    .\scripts\backup_village_data.ps1 -Zip
#>

param(
    [string]$ProjectId = "abudshisha",
    [string]$OutDir = "backups",
    [switch]$Zip
)

$ErrorActionPreference = "Stop"

# إعداد المسارات
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$TargetFolder = Join-Path $PSScriptRoot "..\$OutDir\backup_$Timestamp"
if (-not (Test-Path $TargetFolder)) {
    New-Item -ItemType Directory -Path $TargetFolder -Force | Out-Null
}

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " 💾 بدء النسخ الاحتياطي لبيانات قرية أبوديشيشة ($ProjectId)" -ForegroundColor Green
Write-Host " 📁 المجلد المستهدف: $TargetFolder" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

# قائمة المجموعات الأساسية للنسخ
$Collections = @(
    "phone_directory",
    "emergency_contacts",
    "village_info",
    "medical_center_clinics",
    "village_clinics",
    "pharmacies",
    "service_providers",
    "news",
    "occasions",
    "obituaries",
    "lost_items",
    "village_ads"
)

$BaseUrl = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents"
$SuccessCount = 0
$TotalDocs = 0

foreach ($Col in $Collections) {
    Write-Host " ⏳ جاري نسخ مجموعة: $Col ..." -NoNewline
    $Url = "$BaseUrl/$Col?pageSize=100"
    $OutFile = Join-Path $TargetFolder "$Col.json"

    try {
        $Response = Invoke-RestMethod -Uri $Url -Method Get -TimeoutSec 15 -ErrorAction Stop
        $Docs = @()
        if ($Response.documents) {
            $Docs = $Response.documents
        }

        $Count = $Docs.Count
        $TotalDocs += $Count

        # تحويل مستندات Firestore إلى صيغة نظيفة
        $CleanData = @{
            collection = $Col
            exportedAt = (Get-Date).ToString("o")
            totalCount = $Count
            documents  = $Docs
        }

        $CleanData | ConvertTo-Json -Depth 10 | Set-Content -Path $OutFile -Encoding UTF8
        Write-Host " تم ($Count مستند) ✔" -ForegroundColor Green
        $SuccessCount++
    }
    catch {
        Write-Host " تخطي (يتطلب مصادقة أو فارغ) ⚠️" -ForegroundColor Yellow
        # حفظ ملف فارغ كدليل
        @{
            collection = $Col
            exportedAt = (Get-Date).ToString("o")
            error      = $_.Exception.Message
        } | ConvertTo-Json | Set-Content -Path $OutFile -Encoding UTF8
    }
}

# كتابة ملف الفهرس
$Summary = @{
    projectId    = $ProjectId
    timestamp    = $Timestamp
    dateArabic   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    collections  = $Collections
    successCount = $SuccessCount
    totalDocs    = $TotalDocs
}
$Summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $TargetFolder "backup_summary.json") -Encoding UTF8

Write-Host "`n───────────────────────────────────────────────────────────" -ForegroundColor Cyan
Write-Host " ✅ اكتمل النسخ الاحتياطي بنجاح!" -ForegroundColor Green
Write-Host " 📊 إجمالي المجموعات: $SuccessCount / $($Collections.Count)" -ForegroundColor White
Write-Host " 📄 إجمالي المستندات المحفوظة: $TotalDocs" -ForegroundColor White
Write-Host " 📂 المسار: $TargetFolder" -ForegroundColor Gray

if ($Zip) {
    $ZipPath = "$TargetFolder.zip"
    Write-Host " 🗜️ جاري إنشاء الملف المضغوط: $ZipPath ..." -ForegroundColor Yellow
    Compress-Archive -Path "$TargetFolder\*" -DestinationPath $ZipPath -Force
    Write-Host " 📦 تم إنشاء الملف المضغوط بنجاح!" -ForegroundColor Green
}
Write-Host "───────────────────────────────────────────────────────────`n" -ForegroundColor Cyan
