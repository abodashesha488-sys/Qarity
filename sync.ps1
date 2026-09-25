<#
.SYNOPSIS
    مزامنة آمنة محلية لـ Git مع GitHub - يجعل المستودع المحلي مصدر الحقيقة.

.DESCRIPTION
    يقوم بالآتي بالترتيب:
    1. التحقق من صحة المستودع والحصول على معلومات عن الفرع الحالي.
    2. عرض/عرض عملية مزامنة آمنة للفرع الحالي دون تغيير فرع Git أو فقدان التغييرات المحلية.
    3. إذا كانت هناك تغييرات محلية، يقوم commit لها.
    4. يقوم fetch من remote (لا يوجد pull، rebase، merge، reset، restore، checkout).
    5. يكتشف العلاقة بين الفرع المحلي وremote.
    6. يقوم push بشكل آمن فقط عندما يكون الفرع المحلي هو المصدر الحقيقي للحقيقة.
    7. يدعم بشكل آمن وضعًا اختياريًا لـ force push عند الحاجة.

.PARAMETER Message
    رسالة الـ commit (اختياري، الافتراضي: "sync: update").

.PARAMETER ForceRemote
    وضع اختياري لـ force push فقط عند الحاجة. ليس اختياريًا بشكل افتراضي.

.EXAMPLE
    .\sync.ps1 -Message "feat: تحديث صفحة الإعدادات"
    .\sync.ps1 -ForceRemote -Message "sync: مزامنة محلية للقاعدة المصدرية"
#>

param(
    [string]$Message = "sync: update",
    [switch]$ForceRemote
)

# إعداد المسار
$repoPath = $PSScriptRoot
Set-Location $repoPath

# دالة مساعدة لكتابة التقارير
function Write-Report {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Gray
}

# دالة مساعدة للحصول على معلومات HEAD المحلية
function Get-LocalHeadInfo {
    try {
        $localHead = git rev-parse HEAD 2>$null
        return $localHead
    } catch {
        Write-Host "❌ فشل في قراءة HEAD المحلي: $_" -ForegroundColor Red
        return $null
    }
}

# دالة مساعدة للحصول على معلومات HEAD البعيدة
function Get-RemoteHeadInfo {
    param([string]$branch)
    try {
        $remoteHead = git rev-parse "origin/$branch" 2>$null
        return $remoteHead
    } catch {
        Write-Host "ℹ️ لا يوجد فرع remmote محدد: $_" -ForegroundColor Yellow
        return $null
    }
}

# دالة مساعدة لعرض الحالة مع الألوان
function Write-ColorfulStatus {
    param([string]$status)
    if ($status.StartsWith("M ")) { Write-Host "🔴 modified: $($status.Substring(3))" -ForegroundColor Red }
    elseif ($status.StartsWith("A ")) { Write-Host "🟢 added: $($status.Substring(3))" -ForegroundColor Green }
    elseif ($status.StartsWith("D ")) { Write-Host "🔴 deleted: $($status.Substring(3))" -ForegroundColor Red }
    elseif ($status.StartsWith("R ")) { Write-Host "🟡 renamed: $($status.Substring(3))" -ForegroundColor Yellow }
    elseif ($status.StartsWith("C ")) { Write-Host "🔵 copied: $($status.Substring(3))" -ForegroundColor Cyan }
    elseif ($status.StartsWith("?")) { Write-Host "⚪ untracked: $($status.Substring(2))" -ForegroundColor White }
    else { Write-Host $status -ForegroundColor Gray }
}

# A) التحقق الأولي للإعدادات
Write-Host "🔍 بدء التحقق الأولي..." -ForegroundColor Cyan

# التحقق من وجود مستودع Git
if (-not (Test-Path ".git")) {
    Write-Host "❌ ليس مستودع Git!" -ForegroundColor Red
    exit 1
}

# اكتشاف الفرع الحالي
$currentBranch = git branch --show-current
if (-not $currentBranch) {
    Write-Host "❌ فشل في اكتشاف الفرع الحالي!" -ForegroundColor Red
    exit 1
}

# التحقق من وجود remote
$remoteExists = git remote | Where-Object { $_ -eq "origin" }
if (-not $remoteExists) {
    Write-Host "❌ لا يوجد remote 'origin' محدد!" -ForegroundColor Red
    exit 1
}

# عرض معلومات المستودع
Write-Host "📁 المسار: $repoPath" -ForegroundColor Gray
Write-Host "🌿 الفرع الحالي: $currentBranch" -ForegroundColor Green
Write-Host "📡 remote: origin" -ForegroundColor Gray
$localHead = Get-LocalHeadInfo
Write-Host "💾 HEAD المحلي: $localHead" -ForegroundColor Yellow

# B) عرض التغييرات المحلية
Write-Host "`n📝 التغييرات المحلية:" -ForegroundColor Yellow
$localChanges = git status --short
if ($localChanges) {
    $localChanges | ForEach-Object { Write-ColorfulStatus $_ }
} else {
    Write-Host "✅ لا توجد تغييرات محلية للمزامنة." -ForegroundColor Green
}

# حفظ HEAD المحلي للعرض النهائي
$initialLocalHead = Get-LocalHeadInfo

# C) إذا كانت هناك تغييرات محلية، قم بعمل commit لها
if ($localChanges) {
    Write-Host "`n📦 إضافة التغييرات..." -ForegroundColor Yellow
    git add -A

    Write-Host "💾 إنشاء commit: $Message" -ForegroundColor Yellow
    $commitResult = git commit -m $Message
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ فشل في commit: $commitResult" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ تم إنشاء commit بنجاح" -ForegroundColor Green
} else {
    Write-Host "ℹ️ لا توجد تغييرات محلية للـ commit." -ForegroundColor Yellow
}

# الحصول على HEAD المحلي الجديد بعد commit
$afterCommitLocalHead = Get-LocalHeadInfo

# D) التحقق من العلاقة البعيدة
Write-Host "`n🔍 التحقق من العلاقة البعيدة..." -ForegroundColor Cyan

# Fetch فقط للتأكد من عدم وجود استثناءات
Write-Host "📡 جاري جلب تحديثات الفرع البعيد..." -ForegroundColor Yellow
try {
    git fetch origin $currentBranch
} catch {
    Write-Host "⚠️ فشل في fetch: $_" -ForegroundColor Yellow
}

$remoteHead = Get-RemoteHeadInfo -branch $currentBranch

if (-not $remoteHead) {
    Write-Host "ℹ️ لا يوجد فرع remote محدد 'origin/$currentBranch'" -ForegroundColor Yellow
}

# تحديد العلاقة
$localAhead = $false
$remoteAhead = $false
$diverged = $false

if ($remoteHead) {
    # مقارنة الأنساب
    $localAncestry = git merge-base --is-ancestor $initialLocalHead $remoteHead 2>$null
    $remoteAncestry = git merge-base --is-ancestor $remoteHead $initialLocalHead 2>$null

    if ($localAncestry -eq "true") {
        $localAhead = $true
        Write-Host "📈 الفرع المحلي متقدم على الفرع البعيد بمقدار $(git rev-list --count --merge-base $remoteHead $initialLocalHead) commit(s)." -ForegroundColor Green
    } elseif ($remoteAncestry -eq "true") {
        $remoteAhead = $true
        Write-Host "📥 الفرع البعيد متقدم على الفرع المحلي بمقدار $(git rev-list --count --merge-base $initialLocalHead $remoteHead) commit(s)." -ForegroundColor Yellow
    } else {
        $diverged = $true
        Write-Host "⚠️ تم اكتشاف تباعد: الفرع المحلي والبعيد لهما سجلين غير متطابقين." -ForegroundColor Red
        Write-Host "   سجل HEAD المحلي: $initialLocalHead" -ForegroundColor Gray
        Write-Host "   سجل HEAD البعيد: $remoteHead" -ForegroundColor Gray
    }
}

# E) تحديد الإجراء المطلوب
$actionTaken = "none"

if (-not $remoteHead) {
    # لا يوجد remote محدد، قم push فقط إذا كان هناك شيء ما
    if ($localChanges) {
        Write-Host "🚀 الدفع إلى GitHub (لا يوجد remote محدد)..." -ForegroundColor Yellow
        try {
            git push origin $currentBranch
            $actionTaken = "push"
        } catch {
            Write-Host "❌ فشل في push: $_" -ForegroundColor Red
            exit 1
        }
    }
} elseif ($localAhead) {
    # الفرع المحلي متقدم - قم push بشكل طبيعي
    Write-Host "🚀 الدفع إلى GitHub (الفرع المحلي متقدم)..." -ForegroundColor Yellow
    try {
        git push origin $currentBranch
        $actionTaken = "push"
    } catch {
        Write-Host "❌ فشل في push: $_" -ForegroundColor Red
        exit 1
    }
} elseif ($remoteAhead) {
    # الفرع البعيد متقدم - توقف حسب المتطلبات
    Write-Host "🛑 توقف: الفرع البعيد يحتوي علىCommits غير موجودة في الفرع المحلي." -ForegroundColor Red
    Write-Host "   الحل: راجع التغييرات البعيدة وقم بتنفيذها محلياً، ثم قم بالمزامنة مرة أخرى." -ForegroundColor Yellow
    exit 1
} elseif ($diverged) {
    # تم اكتشاف تباعد - توقف حسب المتطلبات
    Write-Host "🛑 توقف: الفرع المحلي والبعيد متباعدان." -ForegroundColor Red
    Write-Host "   الحل: راجع التغييرات البعيدة، قم بالدمج أو rebase يدوياً، ثم قم بالمزامنة مرة أخرى." -ForegroundColor Yellow
    exit 1
} else {
    # متطابقان - كل شيء جيد
    Write-Host "✅ المستودع المحلي متطابق تماماً مع الفرع البعيد." -ForegroundColor Green
    $actionTaken = "identical"
}

# F) وضع Force Remote الاختياري
if ($ForceRemote) {
    if (-not ($diverged -or $remoteAhead)) {
        Write-Host "⚠️ تحذير: تم استخدام -ForceRemote ولكن الحالة ليست diverged أو remote-ahead. تجاهل -ForceRemote." -ForegroundColor Yellow
    } else {
        Write-Host "" -ForegroundColor White
        Write-Host "⚠️ وضع Force: قمت باستخدام -ForceRemote بشكل صريح." -ForegroundColor Red
        Write-Host "   سيؤدي هذا إلى تجاوز التحقق القياسي ويجعل GitHub يطابق الفرع المحلي تمامًا." -ForegroundColor Yellow
        Write-Host "   هذا قد يؤدي إلى فقدان أي تغييرات موجودة فقط على GitHub." -ForegroundColor Yellow
        Write-Host "   تأكد تمامًا من رغبتك في المتابعة:" -ForegroundColor Yellow
        $confirm = Read-Host "   اضغط Enter للتأكيد أو Ctrl+C للإلغاء"
        Write-Host "" -ForegroundColor White

        try {
            Write-Host "📡 جاري جلب تحديثات الفرع البعيد (مرة أخرى)..." -ForegroundColor Yellow
            git fetch origin $currentBranch
            $remoteHead = Get-RemoteHeadInfo -branch $currentBranch

            Write-Host "🚀 الدفع بقوة إلى GitHub (--force-with-lease)..." -ForegroundColor Red
            git push --force-with-lease origin $currentBranch
            $actionTaken = "force_push"
            Write-Host "✅ تم الدفع بقوة بنجاح" -ForegroundColor Green
        } catch {
            Write-Host "❌ فشل في push بالقوة: $_" -ForegroundColor Red
            exit 1
        }
    }
}

# G) العرض النهائي للحالة
Write-Host "`n📋 العرض النهائي للحالة:" -ForegroundColor Cyan
$finalStatus = git status --short
if ($finalStatus) {
    $finalStatus | ForEach-Object { Write-ColorfulStatus $_ }
} else {
    Write-Host "✅ لا توجد تغييرات." -ForegroundColor Green
}

# H) تقرير التحقق النهائي
Write-Host "`n===== تقرير التحقق النهائي =====" -ForegroundColor Cyan
Write-Host "📁 المسار: $repoPath" -ForegroundColor Gray
Write-Host "🌿 الفرع الحالي: $currentBranch" -ForegroundColor Green
Write-Host "💾 HEAD المحلي الأولي: $initialLocalHead" -ForegroundColor Yellow
Write-Host "💾 HEAD المحلي النهائي: $afterCommitLocalHead" -ForegroundColor Yellow
Write-Host "🔄 حالة commit: $(if ($localChanges) { 'تم إنشاء commit' } else { 'لا يوجد commit' })" -ForegroundColor Gray
Write-Host "📊 حالة remote: $(if (-not $remoteHead) { 'لا يوجد remote' } elseif ($localAhead) { 'الفرع المحلي متقدم' } elseif ($remoteAhead) { 'الفرع البعيد متقدم' } elseif ($diverged) { 'الفرع متباعد' } else { 'متطابق' })" -ForegroundColor Gray
Write-Host "🚀 نتيجة الإجراء: $actionTaken" -ForegroundColor Green
Write-Host "=============================" -ForegroundColor Cyan

# I) الإكمال الناجح
Write-Host "`n✅ اكتملت عملية المزامنة بنجاح!" -ForegroundColor Green
Write-Host "📝 commit: $Message" -ForegroundColor Gray
Write-Host "🌐 المستودع: https://github.com/abodashesha488-sys/Qarity/tree/$currentBranch" -ForegroundColor Cyan
Write-Host "📋 تم حفظ التغييرات المحلية ومزامنتها مع GitHub باستخدام locally-sourced source of truth rule." -ForegroundColor Green
