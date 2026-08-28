# ============================================================================
#  ProxySwitch 一键发布脚本
#
#  用法:
#    .\release.ps1                # 自动 patch 版本 +1（1.0.1 -> 1.0.2）
#    .\release.ps1 -Version 1.1.0 # 指定版本
#    .\release.ps1 -SkipPush      # 不推送（仅本地打包验证，需 tag 已推送）
#
#  流程:
#    1. 提交当前所有改动
#    2. 打 tag v<版本> 并推送
#    3. 下载 GitHub 自动生成的源码包
#    4. 计算 SHA256 + 确认解压目录名
#    5. 更新 proxy-switch.json（version/url/hash/extract_dir）和 ModuleVersion
#    6. 提交并推送 manifest 更新
# ============================================================================
param(
    [string]$Version,
    [switch]$SkipPush
)

$ErrorActionPreference = "Stop"

$Root     = Split-Path $MyInvocation.MyCommand.Path
$Manifest = Join-Path $Root "proxy-switch.json"
$Psd1Path = Join-Path $Root "src\ProxySwitch.psd1"
Set-Location $Root

# ---------- 1. 确定新版本 ----------
$cur = (Get-Content $Manifest -Raw | ConvertFrom-Json).version
if ($Version) {
    if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "版本格式应为 x.y.z，例如 1.1.0" }
    $new = $Version
}
else {
    $parts = $cur.Split('.')
    $parts[2] = [string]([int]$parts[2] + 1)
    $new = $parts -join '.'
}
Write-Host "==> 发布版本: $cur -> $new" -ForegroundColor Cyan

# ---------- 2. 提交当前改动 ----------
git add -A
if (git status --porcelain) {
    git commit -m "chore: pre-release $new"
    Write-Host "==> 已提交改动" -ForegroundColor Green
}
else {
    Write-Host "==> 工作区干净，无需提交" -ForegroundColor DarkGray
}

# ---------- 3. 打 tag 并推送 ----------
if (-not (git tag -l "v$new")) {
    git tag "v$new"
    Write-Host "==> 已打 tag: v$new" -ForegroundColor Green
}
if (-not $SkipPush) {
    git push origin main --tags
    Write-Host "==> 已推送 main + tags" -ForegroundColor Green
}

# ---------- 4. 下载源码包并计算哈希 ----------
$remote = git remote get-url origin
if ($remote -notmatch 'github\.com[:/]([^/]+/[^/.]+)') {
    throw "无法从 remote 解析仓库地址: $remote"
}
$repo = $Matches[1]

$zip = Join-Path $env:TEMP "proxy-switch-$new.zip"
Write-Host "==> 下载: https://github.com/$repo/archive/refs/tags/v$new.zip" -ForegroundColor DarkGray
curl.exe -L -o $zip "https://github.com/$repo/archive/refs/tags/v$new.zip"
if (-not (Test-Path $zip) -or (Get-Item $zip).Length -eq 0) {
    throw "下载失败。若 GitHub 连接不稳定，请开启代理后重试，或手动下载并用 -SkipPush 重跑。"
}

$hash    = (Get-FileHash $zip -Algorithm SHA256).Hash
$extract = Join-Path $env:TEMP "ps-extract-$new"
Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
Expand-Archive $zip -DestinationPath $extract -Force
$dirName = (Get-ChildItem $extract | Select-Object -First 1).Name
Write-Host "==> hash        = $hash" -ForegroundColor Green
Write-Host "==> extract_dir = $dirName" -ForegroundColor Green

# ---------- 5. 更新 manifest 和模块版本 ----------
$j = Get-Content $Manifest -Raw | ConvertFrom-Json
$j.version     = $new
$j.url         = "https://github.com/$repo/archive/refs/tags/v$new.zip"
$j.hash        = $hash
$j.extract_dir = $dirName
$j | ConvertTo-Json -Depth 5 | Set-Content $Manifest -Encoding UTF8

$psd1Content = Get-Content $Psd1Path -Raw
$psd1Content = $psd1Content -replace "ModuleVersion\s*=\s*'[^']*'", "ModuleVersion        = '$new'"
Set-Content $Psd1Path $psd1Content -Encoding UTF8
Write-Host "==> 已更新 proxy-switch.json + ModuleVersion" -ForegroundColor Green

# ---------- 6. 提交并推送 manifest 更新 ----------
git add proxy-switch.json src/ProxySwitch.psd1
if (git status --porcelain) {
    git commit -m "release v$new"
}
if (-not $SkipPush) {
    git push origin main
}

Write-Host ""
Write-Host "发布完成: v$new" -ForegroundColor Green
Write-Host "下一步: scoop update && scoop install proxy-switch"
