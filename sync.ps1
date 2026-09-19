<#
.SYNOPSIS
    مزامنة مستودع Git مع GitHub - يسحب أحدث التغييرات، يضيف تغييراتك، ويدفع كل شيء.

.DESCRIPTION
    يقوم بالآتي بالترتيب:
    1. يخزن التغييرات المؤقتة (stash) بما فيها ملفات Actions
    2. يسحب أحدث التغييرات من GitHub مع rebase
    3. يعيد التغييرات من stash
    4. يحمي ملفات Actions (pubspec.yaml, update.json) لتظل بنسخة GitHub
    5. يضيف تغييراتك، يعمل commit، ويدفع لـ GitHub

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

# 1. Stash جميع التغييرات (بما فيها ملفات Actions مؤقتاً)
Write-Host "📦 تخزين التغييرات مؤقتاً (stash)..." -ForegroundColor Yellow
git stash push --include-untracked -m "sync-script-stash-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# 2. سحب أحدث التغييرات مع rebase
if (-not $SkipPull) {
    Write-Host "📥 سحب أحدث التغييرات من GitHub (rebase)..." -ForegroundColor Yellow
    try {
        git pull --rebase origin main
    } catch {
        Write-Host "❌ فشل في pull --rebase. قد يكون هناك تعارض." -ForegroundColor Red
        Write-Host "💡 استعادة التغييرات: git stash pop" -ForegroundColor Yellow
        git stash pop
        exit 1
    }
}

# 3. استعادة التغييرات من stash
Write-Host "📤 استعادة تغييراتك المحلية..." -ForegroundColor Yellow
try {
    git stash pop
} catch {
    Write-Host "⚠️ تعارض عند استعادة التغييرات. حلّه يدوياً ثم: git add . && git commit" -ForegroundColor Red
    exit 1
}

# 3. حماية ملفات Actions - استعد نسخة GitHub
Write-Host "🔒 حماية ملفات GitHub Actions..." -ForegroundColor Magenta
foreach ($file in @("pubspec.yaml", "update.json")) {
    if (Test-Path $file) {
        git restore $file 2>$null
    }
}

# 4. إضافة جميع التغييرات (باستثناء ملفات Actions المستعادة)
Write-Host "➕ إضافة التغييرات..." -ForegroundColor Yellow
git add -A

# التحقق من وجود تغييرات للـ commit
$newStatus = git status --porcelain
if (-not $newStatus) {
    Write-Host "ℹ️ لا توجد تغييرات جديدة للـ commit (بعد استبعاد ملفات Actions)." -ForegroundColor Yellow
    exit 0
}

# 5. Commit
Write-Host "💾 إنشاء commit: $Message" -ForegroundColor Yellow
git commit -m $Message

# 6. Push
Write-Host "🚀 دفع التغييرات إلى GitHub..." -ForegroundColor Yellow
try {
    git push origin main
} catch {
    Write-Host "❌ فشل في push. جاري محاولة pull ثم push..." -ForegroundColor Red
    git pull --rebase origin main
    git push origin main
}

Write-Host "`n✅ تمت المزامنة بنجاح!" -ForegroundColor Green
Write-Host "📦 commit: $Message" -ForegroundColor Gray
Write-Host "🌐 تحقق من: https://github.com/abodashesha488-sys/Qarity" -ForegroundColor Cyan