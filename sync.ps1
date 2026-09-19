<#
.SYNOPSIS
    مزامنة مستودع Git مع GitHub - يسحب أحدث التغييرات، يضيف تغييراتك، ويدفع كل شيء.

.DESCRIPTION
    يقوم بالآتي بالترتيب:
    1. يتحقق من وجود تغييرات محلية
    2. يخزن الملفات التي يديرها GitHub Actions (pubspec.yaml, update.json) مؤقتاً
    3. يسحب أحدث التغييرات من GitHub مع rebase
    4. يعيد الملفات المدارة من Actions
    4. يضيف تغييراتك، يعمل commit، ويدفع لـ GitHub

.PARAMETER Message
    رسالة الـ commit (اختياري، الافتراضي: "sync: update")

.PARAMETER SkipPull
    يتخطى خطوة pull (للاستخدام عند الرغبة في الدفع فقط)

.EXAMPLE
    .\sync.ps1 -Message "feat: تحديث صفحة الإعدادات"
    .\sync.ps1
    .\sync.ps1 -SkipPull
#>

param(
    [string]$Message = "sync: update",
    [switch]$SkipPull
)

# إعداد المسار
$repoPath = $PSScriptRoot
Set-Location $repoPath

Write-Host "🔄 بدء مزامنة المستودع..." -ForegroundColor Cyan
Write-Host "📁 المسار: $repoPath" -ForegroundColor Gray

# التحقق من وجود مستودع Git
if (-not (Test-Path ".git")) {
    Write-Host "❌ ليس مستودع Git!" -ForegroundColor Red
    exit 1
}

# التحقق من وجود تغييرات
$status = git status --porcelain
if (-not $status) {
    Write-Host "✅ لا توجد تغييرات محلية للمزامنة." -ForegroundColor Green
    if (-not $SkipPull) {
        Write-Host "📥 سحب أحدث التغييرات من GitHub..." -ForegroundColor Yellow
        git pull --rebase origin main
    }
    exit 0
}

Write-Host "📝 التغييرات المحلية:" -ForegroundColor Yellow
git status --short

# الملفات التي يديرها GitHub Actions - لا تلمسها يدوياً
$actionFiles = @("pubspec.yaml", "update.json")
$stashedActionFiles = @()

foreach ($file in $actionFiles) {
    if (Test-Path $file) {
        $fileStatus = git status --porcelain $file
        if ($fileStatus) {
            Write-Host "🔒 حماية ملف Actions: $file" -ForegroundColor Magenta
            # خزن النسخة الحالية
            $content = Get-Content $file -Raw
            $stashedActionFiles += @{ File = $file; Content = $content }
            # استعد النسخة من HEAD (تجاهل التغييرات المحلية)
            git restore $file
        }
    }
}

# سحب أحدث التغييرات مع rebase
if (-not $SkipPull) {
    Write-Host "📥 سحب أحدث التغييرات من GitHub (rebase)..." -ForegroundColor Yellow
    try {
        git pull --rebase origin main
    } catch {
        Write-Host "❌ فشل في pull --rebase. قد يكون هناك تعارض." -ForegroundColor Red
        Write-Host "💡 حل التعارض يدوياً ثم شغل: git rebase --continue" -ForegroundColor Yellow
        # أعد الملفات المحمية
        foreach ($item in $stashedActionFiles) {
            Set-Content -Path $item.File -Value $item.Content -Encoding UTF8
        }
        exit 1
    }
}

# أعد الملفات المدارة من Actions (النسخة الجديدة من GitHub ستبقى، هذا للتأكيد)
foreach ($item in $stashedActionFiles) {
    # لا نعيد الكتابة - نترك نسخة GitHub
    Write-Host "✅ ملف Actions محفوظ بنسخة GitHub: $($item.File)" -ForegroundColor Green
}

# إضافة جميع التغييرات (باستثناء ملفات Actions التي استُعيدت من GitHub)
Write-Host "➕ إضافة التغييرات..." -ForegroundColor Yellow
git add -A

# التحقق مجدداً
$newStatus = git status --porcelain
if (-not $newStatus) {
    Write-Host "ℹ️ لا توجد تغييرات جديدة للـ commit (بعد استبعاد ملفات Actions)." -ForegroundColor Yellow
    exit 0
}

# Commit
Write-Host "💾 إنشاء commit: $Message" -ForegroundColor Yellow
git commit -m $Message

# Push
Write-Host "🚀 دفع التغييرات إلى GitHub..." -ForegroundColor Yellow
git push origin main

Write-Host "`n✅ تمت المزامنة بنجاح!" -ForegroundColor Green
Write-Host "📦 commit: $Message" -ForegroundColor Gray
Write-Host "🌐 تحقق من: https://github.com/abodashesha488-sys/Qarity" -ForegroundColor Cyan