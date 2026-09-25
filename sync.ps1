<#
.SYNOPSIS
    مزامنة آمنة محلية لـ Git مع GitHub - يجعل المستودع المحلي مصدر الحقيقة.

.DESCRIPTION
    يقوم بالآتي:
    1. يتحقق من صحة المستودع والفرع الحالي.
    2. يعرض التغييرات المحلية.
    3. ينشئ commit للتغييرات المحلية إن وجدت.
    4. ينفذ fetch فقط من GitHub.
    5. يحدد العلاقة بين المحلي والبعيد:
       - identical
       - local_ahead
       - remote_ahead
       - diverged
    6. يدفع التغييرات المحلية فقط عندما يكون المحلي متقدمًا.
    7. يتوقف بأمان عند remote_ahead أو diverged.
    8. يدعم -ForceRemote بشكل صريح باستخدام --force-with-lease فقط.

.NOTES
    LOCAL PROJECT = SOURCE OF TRUTH

    ممنوع استخدام:
    git pull
    git merge
    git rebase
    git reset
    git restore
    git checkout
#>

param(
    [string]$Message = "sync: update",
    [switch]$ForceRemote
)

# ============================================================
# إعداد المسار
# ============================================================

$repoPath = $PSScriptRoot
Set-Location $repoPath

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "        SAFE LOCAL → GITHUB SYNCHRONIZATION" -ForegroundColor Cyan
Write-Host "        LOCAL PROJECT = SOURCE OF TRUTH" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# دوال مساعدة
# ============================================================

function Get-LocalHead {
    $result = git rev-parse HEAD 2>$null

    if ($LASTEXITCODE -ne 0 -or -not $result) {
        return $null
    }

    return $result.Trim()
}

function Get-RemoteHead {
    param(
        [string]$Branch
    )

    $result = git rev-parse "origin/$Branch" 2>$null

    if ($LASTEXITCODE -ne 0 -or -not $result) {
        return $null
    }

    return $result.Trim()
}

function Test-RemoteRelationship {
    param(
        [string]$LocalHead,
        [string]$RemoteHead
    )

    # الحالة 1: متطابقان تمامًا
    if ($LocalHead -eq $RemoteHead) {
        return "identical"
    }

    # الحالة 2: remote هو ancestor للـ local
    # أي أن المحلي يحتوي على كل ما في GitHub + commits إضافية
    git merge-base --is-ancestor $RemoteHead $LocalHead 2>$null

    if ($LASTEXITCODE -eq 0) {
        return "local_ahead"
    }

    # الحالة 3: local هو ancestor للـ remote
    # أي أن GitHub يحتوي على commits غير موجودة محليًا
    git merge-base --is-ancestor $LocalHead $RemoteHead 2>$null

    if ($LASTEXITCODE -eq 0) {
        return "remote_ahead"
    }

    # الحالة 4: كلاهما يحتوي على تاريخ مختلف
    return "diverged"
}

function Write-FileStatus {
    param(
        [string]$StatusLine
    )

    if ($StatusLine.Length -lt 2) {
        Write-Host $StatusLine -ForegroundColor Gray
        return
    }

    $code = $StatusLine.Substring(0, 2)
    $file = $StatusLine.Substring(3)

    switch -Regex ($code) {
        "M " { Write-Host "🔴 modified: $file" -ForegroundColor Red; break }
        " M" { Write-Host "🔴 modified: $file" -ForegroundColor Red; break }
        "A " { Write-Host "🟢 added:    $file" -ForegroundColor Green; break }
        "D " { Write-Host "🔴 deleted:  $file" -ForegroundColor Red; break }
        "R " { Write-Host "🟡 renamed:  $file" -ForegroundColor Yellow; break }
        "C " { Write-Host "🔵 copied:   $file" -ForegroundColor Cyan; break }
        "??" { Write-Host "⚪ untracked: $file" -ForegroundColor White; break }
        default {
            Write-Host $StatusLine -ForegroundColor Gray
        }
    }
}

function Stop-Safely {
    param(
        [string]$Message
    )

    Write-Host ""
    Write-Host "🛑 $Message" -ForegroundColor Red
    Write-Host ""
    Write-Host "لم يتم تنفيذ أي Pull / Merge / Rebase / Reset / Restore / Checkout." -ForegroundColor Yellow
    Write-Host "لم يتم حذف أو استبدال أي تغيير محلي." -ForegroundColor Yellow
    exit 1
}

# ============================================================
# 1. التحقق من المستودع
# ============================================================

Write-Host "🔍 التحقق من المستودع..." -ForegroundColor Cyan

if (-not (Test-Path ".git")) {
    Write-Host "❌ هذا المجلد ليس مستودع Git." -ForegroundColor Red
    exit 1
}

# ============================================================
# 2. التحقق من الفرع
# ============================================================

$currentBranch = git branch --show-current 2>$null

if ($LASTEXITCODE -ne 0 -or -not $currentBranch) {
    Write-Host "❌ تعذر تحديد الفرع الحالي." -ForegroundColor Red
    exit 1
}

$currentBranch = $currentBranch.Trim()

# ============================================================
# 3. التحقق من origin
# ============================================================

$remoteExists = git remote 2>$null | Where-Object { $_.Trim() -eq "origin" }

if (-not $remoteExists) {
    Write-Host "❌ لا يوجد remote باسم origin." -ForegroundColor Red
    exit 1
}

# ============================================================
# 4. المعلومات الأولية
# ============================================================

$initialLocalHead = Get-LocalHead

Write-Host ""
Write-Host "📁 المسار: $repoPath" -ForegroundColor Gray
Write-Host "🌿 الفرع: $currentBranch" -ForegroundColor Green
Write-Host "📡 Remote: origin" -ForegroundColor Gray
Write-Host "💾 HEAD المحلي الأولي: $initialLocalHead" -ForegroundColor Yellow

# ============================================================
# 5. التغييرات المحلية
# ============================================================

Write-Host ""
Write-Host "📝 التغييرات المحلية:" -ForegroundColor Yellow

$localChanges = @(git status --short 2>$null)

if ($localChanges.Count -gt 0) {

    foreach ($change in $localChanges) {
        Write-FileStatus $change
    }

    # ========================================================
    # 6. Commit للتغييرات المحلية
    # ========================================================

    Write-Host ""
    Write-Host "📦 إضافة جميع التغييرات المحلية..." -ForegroundColor Yellow

    git add -A

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ فشل git add." -ForegroundColor Red
        exit 1
    }

    Write-Host "💾 إنشاء commit: $Message" -ForegroundColor Yellow

    git commit -m $Message

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ فشل إنشاء commit." -ForegroundColor Red
        exit 1
    }

    Write-Host "✅ تم إنشاء commit بنجاح." -ForegroundColor Green

}
else {

    Write-Host "✅ لا توجد تغييرات محلية غير محفوظة." -ForegroundColor Green
}

# ============================================================
# 7. HEAD بعد الـ commit
# ============================================================

$currentLocalHead = Get-LocalHead

if (-not $currentLocalHead) {
    Write-Host "❌ تعذر قراءة HEAD المحلي بعد commit." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "💾 HEAD المحلي الحالي: $currentLocalHead" -ForegroundColor Yellow

# ============================================================
# 8. Fetch فقط
# ============================================================

Write-Host ""
Write-Host "📡 Fetch من GitHub..." -ForegroundColor Cyan

git fetch origin $currentBranch

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ فشل git fetch." -ForegroundColor Red
    exit 1
}

Write-Host "✅ تم تحديث معلومات GitHub بنجاح." -ForegroundColor Green

# ============================================================
# 9. قراءة remote HEAD
# ============================================================

$remoteHead = Get-RemoteHead -Branch $currentBranch

# ============================================================
# 10. حالة remote غير موجود
# ============================================================

if (-not $remoteHead) {

    Write-Host ""
    Write-Host "ℹ️ الفرع البعيد غير موجود على origin." -ForegroundColor Yellow
    Write-Host "🚀 سيتم إنشاء الفرع على GitHub من النسخة المحلية." -ForegroundColor Green

    git push -u origin $currentBranch

    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ فشل إنشاء الفرع على GitHub." -ForegroundColor Red
        exit 1
    }

    $actionTaken = "push_new_remote_branch"

}
else {

    # ========================================================
    # 11. تحديد العلاقة
    # ========================================================

    $relationshipStatus = Test-RemoteRelationship `
        -LocalHead $currentLocalHead `
        -RemoteHead $remoteHead

    Write-Host ""
    Write-Host "🔍 حالة العلاقة بين المحلي وGitHub: $relationshipStatus" -ForegroundColor Cyan

    $actionTaken = "none"

    # ========================================================
    # IDENTICAL
    # ========================================================

    if ($relationshipStatus -eq "identical") {

        Write-Host "✅ المحلي وGitHub متطابقان تمامًا." -ForegroundColor Green
        $actionTaken = "identical"
    }

    # ========================================================
    # LOCAL AHEAD
    # ========================================================

    elseif ($relationshipStatus -eq "local_ahead") {

        Write-Host "🚀 المحلي متقدم عن GitHub." -ForegroundColor Green
        Write-Host "🚀 سيتم الدفع إلى GitHub بشكل طبيعي..." -ForegroundColor Yellow

        git push origin $currentBranch

        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ فشل push." -ForegroundColor Red
            exit 1
        }

        Write-Host "✅ تم دفع التغييرات إلى GitHub." -ForegroundColor Green
        $actionTaken = "push"
    }

    # ========================================================
    # REMOTE AHEAD
    # ========================================================

    elseif ($relationshipStatus -eq "remote_ahead") {

        if ($ForceRemote) {

            Write-Host ""
            Write-Host "⚠️ تم استخدام -ForceRemote." -ForegroundColor Red
            Write-Host "⚠️ GitHub يحتوي على commits غير موجودة محليًا." -ForegroundColor Red
            Write-Host "⚠️ سيتم استبدال تاريخ GitHub بتاريخ النسخة المحلية." -ForegroundColor Red
            Write-Host ""

            $confirmation = Read-Host "اكتب YES للتأكيد"

            if ($confirmation -cne "YES") {
                Stop-Safely "تم إلغاء ForceRemote. لم يتم تغيير GitHub."
            }

            Write-Host ""
            Write-Host "📡 Fetch أخير قبل force-with-lease..." -ForegroundColor Yellow

            git fetch origin $currentBranch

            if ($LASTEXITCODE -ne 0) {
                Stop-Safely "فشل fetch الأخير. لم يتم تنفيذ force push."
            }

            $remoteHeadBeforeForce = Get-RemoteHead -Branch $currentBranch

            if (-not $remoteHeadBeforeForce) {
                Stop-Safely "تعذر قراءة remote HEAD قبل force push."
            }

            Write-Host "💾 Remote HEAD قبل force push: $remoteHeadBeforeForce" -ForegroundColor Yellow
            Write-Host "🚀 تنفيذ --force-with-lease..." -ForegroundColor Red

            git push --force-with-lease origin $currentBranch

            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ فشل --force-with-lease." -ForegroundColor Red
                exit 1
            }

            Write-Host "✅ تم force push باستخدام --force-with-lease." -ForegroundColor Green
            $actionTaken = "force_push"

        }
        else {

            Stop-Safely `
                "GitHub متقدم عن النسخة المحلية. راجع التغييرات البعيدة يدويًا قبل أي إجراء."
        }
    }

    # ========================================================
    # DIVERGED
    # ========================================================

    elseif ($relationshipStatus -eq "diverged") {

        if ($ForceRemote) {

            Write-Host ""
            Write-Host "⚠️ تم اكتشاف Diverged مع استخدام -ForceRemote." -ForegroundColor Red
            Write-Host "⚠️ المحلي وGitHub يحتويان على تاريخين مختلفين." -ForegroundColor Red
            Write-Host "⚠️ force push قد يؤدي إلى فقدان commits الموجودة فقط على GitHub." -ForegroundColor Red
            Write-Host ""

            $confirmation = Read-Host "اكتب YES للتأكيد"

            if ($confirmation -cne "YES") {
                Stop-Safely "تم إلغاء ForceRemote. لم يتم تغيير GitHub."
            }

            Write-Host ""
            Write-Host "📡 Fetch أخير قبل force-with-lease..." -ForegroundColor Yellow

            git fetch origin $currentBranch

            if ($LASTEXITCODE -ne 0) {
                Stop-Safely "فشل fetch الأخير. لم يتم تنفيذ force push."
            }

            $remoteHeadBeforeForce = Get-RemoteHead -Branch $currentBranch

            if (-not $remoteHeadBeforeForce) {
                Stop-Safely "تعذر قراءة remote HEAD قبل force push."
            }

            Write-Host "💾 Remote HEAD قبل force push: $remoteHeadBeforeForce" -ForegroundColor Yellow
            Write-Host "🚀 تنفيذ --force-with-lease..." -ForegroundColor Red

            git push --force-with-lease origin $currentBranch

            if ($LASTEXITCODE -ne 0) {
                Write-Host "❌ فشل --force-with-lease." -ForegroundColor Red
                exit 1
            }

            Write-Host "✅ تم force push باستخدام --force-with-lease." -ForegroundColor Green
            $actionTaken = "force_push"

        }
        else {

            Stop-Safely `
                "الفرع المحلي وGitHub متباعدان. لم يتم تغيير أي منهما."
        }
    }

    else {

        Stop-Safely "تعذر تحديد حالة العلاقة بين المحلي وGitHub."
    }
}

# ============================================================
# 12. التحقق النهائي
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                 FINAL VERIFICATION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$finalLocalHead = Get-LocalHead
$finalRemoteHead = Get-RemoteHead -Branch $currentBranch
$finalStatus = @(git status --short 2>$null)

Write-Host ""
Write-Host "📁 المسار: $repoPath" -ForegroundColor Gray
Write-Host "🌿 الفرع: $currentBranch" -ForegroundColor Green
Write-Host "💾 HEAD المحلي الأولي: $initialLocalHead" -ForegroundColor Yellow
Write-Host "💾 HEAD المحلي النهائي: $finalLocalHead" -ForegroundColor Yellow
Write-Host "💾 HEAD GitHub النهائي: $finalRemoteHead" -ForegroundColor Yellow
Write-Host "🚀 الإجراء: $actionTaken" -ForegroundColor Green

Write-Host ""
Write-Host "📝 الحالة النهائية:" -ForegroundColor Yellow

if ($finalStatus.Count -eq 0) {
    Write-Host "✅ Working tree نظيف." -ForegroundColor Green
}
else {
    foreach ($change in $finalStatus) {
        Write-FileStatus $change
    }
}

# ============================================================
# 13. التحقق من تطابق Local / Remote بعد العملية
# ============================================================

if ($finalRemoteHead -and ($finalLocalHead -eq $finalRemoteHead)) {

    Write-Host ""
    Write-Host "✅ FINAL CHECK: المحلي وGitHub متطابقان تمامًا." -ForegroundColor Green
    Write-Host "✅ تمت المزامنة بنجاح." -ForegroundColor Green

}
elseif (-not $finalRemoteHead) {

    Write-Host ""
    Write-Host "⚠️ تعذر قراءة remote HEAD للتحقق النهائي." -ForegroundColor Yellow
    exit 1

}
else {

    Write-Host ""
    Write-Host "⚠️ المحلي وGitHub ليسا متطابقين بعد العملية." -ForegroundColor Red
    Write-Host "🛑 لن يتم اعتبار المزامنة ناجحة." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🌐 https://github.com/abodashesha488-sys/Qarity/tree/$currentBranch" -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""