<#
.SYNOPSIS
    نشر كامل للمشروع في خطوة واحدة: فحص الجودة + رفع الكود + بناء وإصدار APK + تحديث إصدار Firestore.

.DESCRIPTION
    يغطي السكربت الثلاث مراحل الكاملة لنشر المشروع:

    [المرحلة 0] التحقق من المتطلبات (Git، Flutter، Remote، GitHub Token)
    [المرحلة 1] فحص الجودة ثم رفع الكود
        • flutter analyze  (بوابة جودة — يتوقف عند أي خطأ)
        • flutter test     (بوابة جودة — يمكن تخطيها بـ -SkipTests)
        • git add + commit (مع استبعاد مجلدات أدوات الـ AI)
        • git fetch + تحديد العلاقة بين المحلي والبعيد
        • git push فقط عندما يكون المحلي متقدمًا، أو توقف آمن
    [المرحلة 2] بناء وإصدار APK (تلقائيًا عبر GitHub Actions)
        • تشغيل workflow «Build & Release APK + Update Firestore Version»
        • يبني APK موقّعًا، ينشئ GitHub Release، يحفظ update.json
        • يحدّث رقم الإصدار تلقائيًا (build_number.txt)
    [المرحلة 3] تحديث إصدار Firestore (ضمن نفس workflow المرحلة 2)
        • يكتب app_version/current الذي يقرأه التطبيق عبر UpdateService
        • مراقبة تشغيل الـ workflow حتى الاكتمال مع تقرير النتيجة

    سير العمل هذا يبني نفسه على GitHub لذا لا يحتاج Flutter SDK كامل محليًا.

.PARAMETER Message
    رسالة الـ commit للتعديلات المحلية.

.PARAMETER ReleaseNotes
    رسالة التحديث التي تظهر للمستخدم في التطبيق (لتحديث Firestore).
    افتراضيًا تستخدم رسالة الـ commit.

.PARAMETER Version
    اسم الإصدار صراحةً (مثال: 1.1.0). اتركه فارغًا للزيادة التلقائية.

.PARAMETER MinBuild
    أقل رقم بناء يجبر المستخدم على التحديث (افتراضيًا = البناء الحالي = اختياري).

.PARAMETER Maintenance
    تفعيل وضع الصيانة (يغلق التطبيق تمامًا).

.PARAMETER MaintenanceMessage
    رسالة تظهر عند تفعيل وضع الصيانة.

.PARAMETER ForceRemote
    استبدال تاريخ GitHub بالنسخة المحلية (يستخدم --force-with-lease فقط).

.PARAMETER SkipTests
    تخطي بوابة flutter test ( flutter analyze يبقى إلزاميًا).

.PARAMETER SkipAnalyze
    تخطي بوابة flutter analyze (غير موصى به).

.PARAMETER SkipRelease
    تنفيذ رفع الكود فقط بدون المرحلتين 2 و 3.

.EXAMPLE
    .\sync.ps1 -Message "fix: تصحيح لون التعليقات" -ReleaseNotes "تحسين ألوان التعليقات وإصلاحات"
    ينشئ commit، يرفعه، يشغّل workflow البناء والإصدار، ويراقبه حتى يكتمل.

.EXAMPLE
    .\sync.ps1 -Message "sync: تحديث" -SkipRelease
    ينفذ رفع الكود فقط (بدون بناء APK).

.NOTES
    LOCAL PROJECT = SOURCE OF TRUTH
    لا يستخدم السكربت git pull / merge / rebase / reset / restore / checkout على التغييرات المحلية.
    إذا أضاف الـ workflow التزامات على GitHub (زيادة الإصدار)، سيتوقف السكربت
    بأمان في المرة التالية حتى تدمجها يدويًا أو تستخدم -AllowPullWorkflow.
#>

param(
    [string]$Message = "sync: update",
    [string]$ReleaseNotes = "",
    [string]$Version = "",
    [string]$MinBuild = "",
    [switch]$Maintenance,
    [string]$MaintenanceMessage = "",
    [switch]$ForceRemote,
    [switch]$SkipTests,
    [switch]$SkipAnalyze,
    [switch]$SkipRelease,
    [switch]$AllowPullWorkflow
)

# ============================================================
# إعدادات ثابتة
# ============================================================

$repoPath = $PSScriptRoot
Set-Location $repoPath

$WORKFLOW_ID = "release-apk.yml"
$WORKFLOW_NAME = "Build & Release APK + Update Firestore Version"
$MAX_WAIT_MINUTES = 30
$POLL_INTERVAL_SECONDS = 20

# مجلدات أدوات الـ AI يجب ألا تُرفع أبدًا
$AI_DIRS = @(".kilo", ".kilocode")

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              FULL PROJECT PUBLISH PIPELINE" -ForegroundColor Cyan
Write-Host "     QUALITY -> GIT -> BUILD APK -> FIRESTORE VERSION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# دوال مساعدة
# ============================================================

function Get-LocalHead {
    $result = git rev-parse HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $result) { return $null }
    return $result.Trim()
}

function Get-RemoteHead {
    param([string]$Branch)
    $result = git rev-parse "origin/$Branch" 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $result) { return $null }
    return $result.Trim()
}

function Test-RemoteRelationship {
    param([string]$LocalHead, [string]$RemoteHead)
    if ($LocalHead -eq $RemoteHead) { return "identical" }
    git merge-base --is-ancestor $RemoteHead $LocalHead 2>$null
    if ($LASTEXITCODE -eq 0) { return "local_ahead" }
    git merge-base --is-ancestor $LocalHead $RemoteHead 2>$null
    if ($LASTEXITCODE -eq 0) { return "remote_ahead" }
    return "diverged"
}

function Write-FileStatus {
    param([string]$StatusLine)
    if ($StatusLine.Length -lt 2) { Write-Host $StatusLine -ForegroundColor Gray; return }
    $code = $StatusLine.Substring(0, 2)
    $file = $StatusLine.Substring(3)
    switch -Regex ($code) {
        "M " { Write-Host "modified: $file" -ForegroundColor Red; break }
        " M" { Write-Host "modified: $file" -ForegroundColor Red; break }
        "A " { Write-Host "added:    $file" -ForegroundColor Green; break }
        "D " { Write-Host "deleted:  $file" -ForegroundColor Red; break }
        "R " { Write-Host "renamed:  $file" -ForegroundColor Yellow; break }
        "C " { Write-Host "copied:   $file" -ForegroundColor Cyan; break }
        "??" { Write-Host "untracked: $file" -ForegroundColor DarkGray; break }
        default { Write-Host $StatusLine -ForegroundColor Gray }
    }
}

function Stop-Safely {
    param([string]$Message)
    Write-Host ""
    Write-Host "STOPPED: $Message" -ForegroundColor Red
    Write-Host "لم يتم تنفيذ أي Pull / Merge / Rebase / Reset / Restore / Checkout على التغييرات المحلية." -ForegroundColor Yellow
    Write-Host "لم يتم حذف أو استبدال أي تغيير محلي." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "!!! فشل النشر — لم تكتمل المراحل 2 و 3 (بناء APK + تحديث Firestore)" -ForegroundColor Red
    exit 1
}

function Stop-Quality {
    param([string]$Stage, [string]$Detail)
    Write-Host ""
    Write-Host "QUALITY GATE FAILED: $Stage" -ForegroundColor Red
    Write-Host $Detail -ForegroundColor Yellow
    Write-Host ""
    Write-Host "تم إيقاف النشر قبل رفع الكود. صحّح الأخطاء ثم أعد تشغيل السكربت." -ForegroundColor Red
    Write-Host "إذا كنت متأكدًا يمكنك التخطي: -SkipTests أو -SkipAnalyze" -ForegroundColor DarkGray
    exit 1
}

# ───────────────────────── GitHub API ─────────────────────────

function Get-GitHubToken {
    # نأخذ التوكن من مخزن بيانات اعتماد Git (git credential store).
    # نستخدم Process مباشرةً بدل الأنبوب لأن Git Credential Manager
    # يكتب رسائل تشخيصية إلى stderr، ومع ErrorActionPreference=Stop
    # يُعتبر ذلك استثناءً فيتبلع catch التوكن الصحيح. هنا نلتقط stdout فقط.
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "git"
        $psi.Arguments = "credential fill"
        $psi.UseShellExecute = $false
        $psi.RedirectStandardInput = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true
        $psi.WorkingDirectory = $repoPath

        $proc = [System.Diagnostics.Process]::Start($psi)
        $proc.StandardInput.WriteLine("protocol=https")
        $proc.StandardInput.WriteLine("host=github.com")
        $proc.StandardInput.WriteLine("")
        $proc.StandardInput.Close()

        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit(15000) | Out-Null
        if (-not $proc.HasExited) { try { $proc.Kill() } catch {} }

        Write-Host "  credential fill: exit=$($proc.ExitCode) stdout=$($stdout.Length) chars stderr=$($stderr.Length) chars" -ForegroundColor DarkGray
        if ($proc.ExitCode -ne 0 -and $stderr.Length -gt 0) {
            Write-Host "  credential fill stderr: $stderr" -ForegroundColor DarkGray
        }

        foreach ($line in ($stdout -split "`r?`n")) {
            if ($line -match '^password=(.+)$') {
                return $Matches[1]
            }
        }
    } catch {
        Write-Host "استثناء أثناء جلب التوكن: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
    return $null
}

function Get-RepoSlug {
    try {
        $url = (git remote get-url origin 2>$null).ToString()
        if ($url -match 'github\.com[/:]([^/]+)/(.+?)(\.git)?$') {
            return @{ Owner = $Matches[1]; Repo = $Matches[2] }
        }
    } catch {}
    return $null
}

function Invoke-GitHubApi {
    param(
        [string]$Method,
        [string]$Endpoint,
        $Body,
        [string]$Token,
        [string]$Owner,
        [string]$Repo
    )
    $uri = "https://api.github.com/repos/$Owner/$Repo$Endpoint"
    $headers = @{
        Authorization = "Bearer $Token"
        Accept        = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
        "User-Agent"  = "Qarity-sync-ps1"
    }
    $params = @{
        Uri     = $uri
        Method  = $Method
        Headers = $headers
    }
    if ($null -ne $Body) {
        $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
        $params["ContentType"] = "application/json"
    }
    return Invoke-RestMethod @params
}

# ============================================================
# المرحلة 0: التحقق من المتطلبات
# ============================================================

Write-Host "[Stage 0] التحقق من المتطلبات..." -ForegroundColor Cyan

if (-not (Test-Path ".git")) {
    Write-Host "هذا المجلد ليس مستودع Git." -ForegroundColor Red
    exit 1
}

$currentBranch = (git branch --show-current 2>$null).ToString().Trim()
if ($LASTEXITCODE -ne 0 -or -not $currentBranch) {
    Write-Host "تعذر تحديد الفرع الحالي." -ForegroundColor Red
    exit 1
}

$remoteExists = git remote 2>$null | Where-Object { $_.Trim() -eq "origin" }
if (-not $remoteExists) {
    Write-Host "لا يوجد remote باسم origin." -ForegroundColor Red
    exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "flutter غير متوفر في PATH — مطلوب لبوابة الجودة." -ForegroundColor Red
    Write-Host "إذا كنت تريد النشر فقط استخدم: -SkipTests -SkipAnalyze" -ForegroundColor DarkGray
    exit 1
}

$repoSlug = Get-RepoSlug
if (-not $repoSlug) {
    Write-Host "تعذر تحديد المالك/المستودع من remote origin." -ForegroundColor Red
    exit 1
}

$initialLocalHead = Get-LocalHead
$pushedSha = $initialLocalHead   # sha الذي سيكون عليه الـ workflow

Write-Host ""
Write-Host "المسار:      $repoPath" -ForegroundColor Gray
Write-Host "الفرع:       $currentBranch" -ForegroundColor Green
Write-Host "المستودع:    $($repoSlug.Owner)/$($repoSlug.Repo)" -ForegroundColor Gray
Write-Host "HEAD المحلي: $initialLocalHead" -ForegroundColor Yellow

# ============================================================
# المرحلة 1أ: بوابة الجودة
# ============================================================

Write-Host ""
Write-Host "[Stage 1a] فحص الجودة..." -ForegroundColor Cyan

if (-not $SkipAnalyze) {
    Write-Host "تشغيل flutter analyze..." -ForegroundColor Yellow
    $analyzeOutput = flutter analyze --no-fatal-infos 2>&1
    $analyzeOutput | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    if ($LASTEXITCODE -ne 0) {
        Stop-Quality -Stage "flutter analyze" -Detail ($analyzeOutput | Out-String)
    }
    Write-Host "flutter analyze: ناجح" -ForegroundColor Green
} else {
    Write-Host "تم تخطي flutter analyze (-SkipAnalyze)" -ForegroundColor DarkGray
}

if (-not $SkipTests) {
    Write-Host "تشغيل flutter test..." -ForegroundColor Yellow
    $testOutput = flutter test 2>&1
    $tail = $testOutput | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] } | Select-Object -Last 5
    $tail | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    if ($LASTEXITCODE -ne 0) {
        Stop-Quality -Stage "flutter test" -Detail ($testOutput | Out-String)
    }
    Write-Host "flutter test: ناجح" -ForegroundColor Green
} else {
    Write-Host "تم تخطي flutter test (-SkipTests)" -ForegroundColor DarkGray
}

# ============================================================
# المرحلة 1ب: الالتزام ورفع الكود
# ============================================================

Write-Host ""
Write-Host "[Stage 1b] الالتزام ورفع الكود..." -ForegroundColor Cyan

$localChanges = @(git status --short 2>$null)

if ($localChanges.Count -gt 0) {
    foreach ($change in $localChanges) { Write-FileStatus $change }

    git add -A
    if ($LASTEXITCODE -ne 0) { Write-Host "فشل git add." -ForegroundColor Red; exit 1 }

    # حماية إضافية: لا نرفع مجلدات أدوات الـ AI أبدًا
    foreach ($d in $AI_DIRS) {
        if (Test-Path $d) {
            git reset -q -- $d 2>$null
            if ($LASTEXITCODE -eq 0) { Write-Host "استبعاد مجلد أدوات الـ AI: $d" -ForegroundColor DarkGray }
        }
    }

    # نتحقق أنه لا يوجد ملف أدوات AI متبقٍ في المنطقة المؤقتة
    $stagedAi = @(git diff --cached --name-only 2>$null | Where-Object { $_ -match '^\.(kilo|kilocode)/' })
    if ($stagedAi.Count -gt 0) {
        Write-Host "تم اكتشاف ملفات أدوات AI في المنطقة المؤقتة — تم رفض الرفع:" -ForegroundColor Red
        $stagedAi | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        exit 1
    }

    Write-Host "إنشاء commit: $Message" -ForegroundColor Yellow
    git commit -m $Message
    if ($LASTEXITCODE -ne 0) { Write-Host "فشل إنشاء commit." -ForegroundColor Red; exit 1 }
    Write-Host "تم إنشاء commit بنجاح." -ForegroundColor Green
} else {
    Write-Host "لا توجد تغييرات محلية غير محفوظة." -ForegroundColor Green
}

$currentLocalHead = Get-LocalHead
if (-not $currentLocalHead) { Write-Host "تعذر قراءة HEAD المحلي بعد commit." -ForegroundColor Red; exit 1 }
Write-Host "HEAD المحلي الحالي: $currentLocalHead" -ForegroundColor Yellow

Write-Host "Fetch من GitHub..." -ForegroundColor Yellow
git fetch origin $currentBranch | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "فشل git fetch." -ForegroundColor Red; exit 1 }

$remoteHead = Get-RemoteHead -Branch $currentBranch

if (-not $remoteHead) {
    Write-Host "الفرع البعيد غير موجود على origin — سيتم إنشاؤه من النسخة المحلية." -ForegroundColor Green
    git push -u origin $currentBranch
    if ($LASTEXITCODE -ne 0) { Write-Host "فشل إنشاء الفرع على GitHub." -ForegroundColor Red; exit 1 }
    $actionTaken = "push_new_remote_branch"
} else {
    $relationshipStatus = Test-RemoteRelationship -LocalHead $currentLocalHead -RemoteHead $remoteHead
    Write-Host "حالة العلاقة بين المحلي وGitHub: $relationshipStatus" -ForegroundColor Cyan
    $actionTaken = "none"

    if ($relationshipStatus -eq "identical") {
        Write-Host "المحلي وGitHub متطابقان تمامًا." -ForegroundColor Green
        $actionTaken = "identical"
    } elseif ($relationshipStatus -eq "local_ahead") {
        Write-Host "المحلي متقدم عن GitHub — جاري الدفع..." -ForegroundColor Yellow
        git push origin $currentBranch
        if ($LASTEXITCODE -ne 0) { Write-Host "فشل push." -ForegroundColor Red; exit 1 }
        Write-Host "تم دفع التغييرات إلى GitHub." -ForegroundColor Green
        $actionTaken = "push"
    } elseif ($relationshipStatus -eq "remote_ahead") {
        # غالبًا سببها التزامات workflow زيادة الإصدار من النشر السابق
        if ($AllowPullWorkflow) {
            Write-Host "GitHub متقدم (التزامات workflow سابقة). دمجها محليًا بأمان (ff-only)..." -ForegroundColor Yellow
            git merge --ff-only "origin/$currentBranch"
            if ($LASTEXITCODE -ne 0) {
                Stop-Safely "تعذر الدمج السريع. راجع التغييرات البعيدة يدويًا."
            }
            Write-Host "تمت مزامنة التزامات workflow محليًا." -ForegroundColor Green
            $currentLocalHead = Get-LocalHead
            $actionTaken = "pull_workflow_ff"
        } elseif ($ForceRemote) {
            Write-Host "تم استخدام -ForceRemote — GitHub يحتوي على commits غير موجودة محليًا." -ForegroundColor Red
            $confirmation = Read-Host "اكتب YES لتأكيد استبدال تاريخ GitHub"
            if ($confirmation -cne "YES") { Stop-Safely "تم إلغاء ForceRemote. لم يتم تغيير GitHub." }
            git fetch origin $currentBranch | Out-Null
            git push --force-with-lease origin $currentBranch
            if ($LASTEXITCODE -ne 0) { Write-Host "فشل --force-with-lease." -ForegroundColor Red; exit 1 }
            Write-Host "تم force push باستخدام --force-with-lease." -ForegroundColor Green
            $actionTaken = "force_push"
        } else {
            Write-Host ""
            Write-Host "GitHub متقدم عن النسخة المحلية (غالبًا التزامات زيادة الإصدار من نشر سابق)." -ForegroundColor Yellow
            Write-Host "الخيارات:" -ForegroundColor Yellow
            Write-Host "  1) أعد التشغيل مع -AllowPullWorkflow  لدمجها محليًا بأمان (موصى به)" -ForegroundColor Green
            Write-Host "  2) أو راجعها يدويًا: git log origin/$currentBranch --oneline" -ForegroundColor DarkGray
            Stop-Safely "يجب دمج التغييرات البعيدة قبل المتابعة."
        }
    } elseif ($relationshipStatus -eq "diverged") {
        if ($ForceRemote) {
            Write-Host "تم اكتشاف Diverged مع -ForceRemote — قد يُفقد commits موجودة فقط على GitHub." -ForegroundColor Red
            $confirmation = Read-Host "اكتب YES للتأكيد"
            if ($confirmation -cne "YES") { Stop-Safely "تم إلغاء ForceRemote. لم يتم تغيير GitHub." }
            git fetch origin $currentBranch | Out-Null
            git push --force-with-lease origin $currentBranch
            if ($LASTEXITCODE -ne 0) { Write-Host "فشل --force-with-lease." -ForegroundColor Red; exit 1 }
            Write-Host "تم force push باستخدام --force-with-lease." -ForegroundColor Green
            $actionTaken = "force_push"
        } else {
            Stop-Safely "الفرع المحلي وGitHub متباعدان. لم يتم تغيير أي منهما."
        }
    } else {
        Stop-Safely "تعذر تحديد حالة العلاقة بين المحلي وGitHub."
    }
}

# sha الذي سيعمل عليه workflow = آخر محلي بعد كل العمليات
$pushedSha = Get-LocalHead

Write-Host ""
Write-Host "[Stage 1] اكتملت — الكود على GitHub: $pushedSha" -ForegroundColor Green

if ($SkipRelease) {
    Write-Host ""
    Write-Host "تم تخطي المراحل 2 و 3 (-SkipRelease). اكتمل رفع الكود فقط." -ForegroundColor Green
    Write-Host "https://github.com/$($repoSlug.Owner)/$($repoSlug.Repo)/tree/$currentBranch" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    exit 0
}

# ============================================================
# المرحلة 2 و 3: بناء وإصدار APK + تحديث Firestore
# ============================================================

Write-Host ""
Write-Host "[Stage 2 + 3] بناء وإصدار APK + تحديث إصدار Firestore..." -ForegroundColor Cyan

$ghToken = Get-GitHubToken
if (-not $ghToken) {
    Write-Host ""
    Write-Host "تعذر الحصول على GitHub token من مخزن بيانات اعتماد Git." -ForegroundColor Red
    Write-Host "الكود تم رفعه بالفعل. يمكنك:" -ForegroundColor Yellow
    Write-Host "  1) تسجيل الدخول: git config --global credential.helper store ثم git push مرة" -ForegroundColor DarkGray
    Write-Host "  2) أو تشغيل الـ workflow يدويًا:" -ForegroundColor Green
    Write-Host "     https://github.com/$($repoSlug.Owner)/$($repoSlug.Repo)/actions/workflows/$WORKFLOW_ID" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "!!! المرحلتان 2 و 3 لم تكتمل — الكود رُفع لكن التطبيق لم يُحدّث." -ForegroundColor Red
    exit 2
}

$notes = if ([string]::IsNullOrWhiteSpace($ReleaseNotes)) { $Message } else { $ReleaseNotes }

# قراءة رقم البناء الحالي للعرض
$currentBuildNo = 0
if (Test-Path "build_number.txt") {
    [int]::TryParse(((Get-Content "build_number.txt" -ErrorAction SilentlyContinue) -replace '\s', ''), [ref]$currentBuildNo) | Out-Null
}
$nextBuildNo = $currentBuildNo + 1
Write-Host "رقم البناء الحالي: $currentBuildNo -> التالي المتوقع: $nextBuildNo" -ForegroundColor Gray

# التحقق من وجود الـ workflow
try {
    $wf = Invoke-GitHubApi -Method "GET" -Endpoint "/actions/workflows/$WORKFLOW_ID" -Token $ghToken -Owner $repoSlug.Owner -Repo $repoSlug.Repo
} catch {
    Write-Host "فشل العثور على workflow '$WORKFLOW_ID'." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit 2
}
if (-not $wf -or $wf.state -ne "active") {
    Write-Host "workflow '$WORKFLOW_ID' غير نشط أو غير موجود." -ForegroundColor Red
    exit 2
}
Write-Host "workflow نشط: $($wf.name)" -ForegroundColor Green

# تشغيل الـ workflow
$dispatchInputs = [ordered]@{
    message = $notes
}
if (-not [string]::IsNullOrWhiteSpace($Version))   { $dispatchInputs["version"] = $Version }
if (-not [string]::IsNullOrWhiteSpace($MinBuild))  { $dispatchInputs["min_build"] = $MinBuild }
$dispatchInputs["maintenance"] = if ($Maintenance) { "true" } else { "false" }
if (-not [string]::IsNullOrWhiteSpace($MaintenanceMessage)) { $dispatchInputs["maintenance_message"] = $MaintenanceMessage }

$dispatchBody = [ordered]@{
    ref    = $currentBranch
    inputs = $dispatchInputs
}

$dispatchTime = (Get-Date).ToUniversalTime()
Write-Host "تشغيل workflow على الفرع '$currentBranch'..." -ForegroundColor Yellow
Write-Host "رسالة التحديث: $notes" -ForegroundColor Gray

try {
    Invoke-GitHubApi -Method "POST" -Endpoint "/actions/workflows/$WORKFLOW_ID/dispatches" -Body $dispatchBody -Token $ghToken -Owner $repoSlug.Owner -Repo $repoSlug.Repo | Out-Null
} catch {
    Write-Host "فشل تشغيل workflow." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    exit 2
}
Write-Host "تم إرسال أمر التشغيل (HTTP 204 = نجاح)." -ForegroundColor Green

# ──────────────── البحث عن تشغيل workflow ────────────────

Write-Host ""
Write-Host "البحث عن تشغيل الـ workflow..." -ForegroundColor Yellow

$workflowRun = $null
$discoveryDeadline = (Get-Date).ToUniversalTime().AddSeconds(90)
while ((Get-Date).ToUniversalTime -lt $discoveryDeadline) {
    Start-Sleep -Seconds 5
    try {
        $runs = Invoke-GitHubApi -Method "GET" -Endpoint "/actions/runs?per_page=20&event=workflow_dispatch" -Token $ghToken -Owner $repoSlug.Owner -Repo $repoSlug.Repo
    } catch { continue }
    if (-not $runs -or -not $runs.workflow_runs) { continue }
    $candidate = $runs.workflow_runs | Where-Object {
        $_.name -eq $WORKFLOW_NAME -and
        $_.head_sha -eq $pushedSha -and
        ([datetime]$_.created_at) -ge $dispatchTime.AddMinutes(-2)
    } | Select-Object -First 1
    if ($candidate) { $workflowRun = $candidate; break }
}

if (-not $workflowRun) {
    Write-Host "تعذر العثور على تشغيل الـ workflow (قد يكون في قائمة الانتظار)." -ForegroundColor Yellow
    Write-Host "راقبه يدويًا:" -ForegroundColor Yellow
    Write-Host "  https://github.com/$($repoSlug.Owner)/$($repoSlug.Repo)/actions/workflows/$WORKFLOW_ID" -ForegroundColor Cyan
    exit 3
}

$runId = $workflowRun.id
$runUrl = $workflowRun.html_url
Write-Host "تم العثور على التشغيل: #$runId" -ForegroundColor Green
Write-Host "الرابط: $runUrl" -ForegroundColor Cyan

# ──────────────── مراقبة التشغيل حتى الاكتمال ────────────────

Write-Host ""
Write-Host "مراقبة التشغيل (انتهاء المهلة: $MAX_WAIT_MINUTES دقيقة)..." -ForegroundColor Yellow

$deadline = (Get-Date).ToUniversalTime().AddMinutes($MAX_WAIT_MINUTES)
$lastStatus = ""
$waited = 0

while ((Get-Date).ToUniversalTime -lt $deadline) {
    Start-Sleep -Seconds $POLL_INTERVAL_SECONDS
    $waited += $POLL_INTERVAL_SECONDS

    try {
        $status = Invoke-GitHubApi -Method "GET" -Endpoint "/actions/runs/$runId" -Token $ghToken -Owner $repoSlug.Owner -Repo $repoSlug.Repo
    } catch {
        Write-Host "  [$waited ث] تعذر جلب الحالة، إعادة المحاولة..." -ForegroundColor DarkGray
        continue
    }

    $curStatus = "$($status.status) / $($status.conclusion)"
    if ($curStatus -ne $lastStatus) {
        Write-Host "  [$waited ث] الحالة: $curStatus" -ForegroundColor Cyan
        $lastStatus = $curStatus
    } else {
        Write-Host "." -NoNewline -ForegroundColor DarkGray
    }

    if ($status.status -eq "completed") {
        Write-Host ""
        $conclusion = $status.conclusion
        if ($conclusion -eq "success") {
            Write-Host "اكتمل الـ workflow بنجاح." -ForegroundColor Green
            break
        } else {
            Write-Host ""
            Write-Host "اكتمل الـ workflow لكن بنتيجة: $conclusion" -ForegroundColor Red
            Write-Host "السجل الكامل: $runUrl" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "!!! فشل بناء/إصدار APK — تحقق من سجل التشغيل، أو أعد المحاولة." -ForegroundColor Red
            exit 4
        }
    }
}

if ((Get-Date).ToUniversalTime -ge $deadline) {
    Write-Host ""
    Write-Host "انتهت المهلة ($MAX_WAIT_MINUTES دقيقة) بينما لا يزال التشغيل جاريًا." -ForegroundColor Yellow
    Write-Host "العملية قد تكون مستمرة على GitHub. الرابط:" -ForegroundColor Yellow
    Write-Host "  $runUrl" -ForegroundColor Cyan
    exit 3
}

# ============================================================
# التحقق النهائي + التقرير
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                PUBLISH RESULT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# نسحب أحدث حالة للـ HEAD البعيد (workflow يضيف التزامات)
git fetch origin $currentBranch | Out-Null
$finalRemoteHead = Get-RemoteHead -Branch $currentBranch

Write-Host ""
Write-Host "الفرع:                 $currentBranch" -ForegroundColor Green
Write-Host "الـ commit الذي رُفع:  $pushedSha" -ForegroundColor Yellow
Write-Host "GitHub HEAD بعد النشر: $finalRemoteHead" -ForegroundColor Yellow
if ($finalRemoteHead -and $finalRemoteHead -ne $pushedSha) {
    Write-Host "  (أضاف الـ workflow التزامات: bump version + update.json)" -ForegroundColor DarkGray
    Write-Host "  في المرة التالية شغّل: .\sync.ps1 ... -AllowPullWorkflow" -ForegroundColor Yellow
}

Write-Host "الإجراء على Git:       $actionTaken" -ForegroundColor Green
Write-Host "تغييرات محلية:        $((@(git status --short 2>$null)).Count)" -ForegroundColor Gray

Write-Host ""
Write-Host "APK Release:" -ForegroundColor Yellow
Write-Host "  https://github.com/$($repoSlug.Owner)/$($repoSlug.Repo)/releases/latest/download/Qarity.apk" -ForegroundColor Cyan
Write-Host "تشغيل الـ workflow:" -ForegroundColor Yellow
Write-Host "  $runUrl" -ForegroundColor Cyan

Write-Host ""
Write-Host "تم نشر المشروع كاملًا: الكود + APK + تحديث Firestore (app_version/current)." -ForegroundColor Green
Write-Host "المراحل الثلاث اكتملت بنجاح." -ForegroundColor Green

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
