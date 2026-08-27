# ============================================================================
#  ProxySwitch 安装脚本（scoop installer 调用，也可手动运行）
#
#  作用:
#    1. 复制模块到 Documents\PowerShell\Modules\ProxySwitch 和 WindowsPowerShell\Modules
#    2. 向 PowerShell 7 / Windows PowerShell 5.1 的 $PROFILE 追加
#       Import-Module ProxySwitch + proxy autodetect（幂等，可重复安装）
# ============================================================================
$ErrorActionPreference = "Stop"

$ModuleName = "ProxySwitch"
$SourceDir  = Split-Path $MyInvocation.MyCommand.Path
$ModuleSrc  = Join-Path $SourceDir "src"
$DocsDir    = [Environment]::GetFolderPath("MyDocuments")

# 1. 复制模块（PS7 与 PS5.1 两个模块目录都装）
$Destinations = @(
    (Join-Path $DocsDir "PowerShell\Modules\$ModuleName"),
    (Join-Path $DocsDir "WindowsPowerShell\Modules\$ModuleName")
)
foreach ($dest in $Destinations) {
    New-Item -ItemType Directory -Force $dest | Out-Null
    Copy-Item (Join-Path $ModuleSrc "*") $dest -Recurse -Force
    Write-Host "模块已安装: $dest"
}

# 2. 写入 $PROFILE 引导（幂等：已有标记块先移除再追加）
$ProfileFiles = @(
    (Join-Path $DocsDir "PowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $DocsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
)

$block = @(
    "# === ProxySwitch begin ===",
    "Import-Module $ModuleName",
    "proxy autodetect",
    "# === ProxySwitch end ==="
) -join "`r`n"

foreach ($pf in $ProfileFiles) {
    $dir = Split-Path $pf -Parent
    New-Item -ItemType Directory -Force $dir | Out-Null
    $content = if (Test-Path $pf) { [string](Get-Content $pf -Raw) } else { "" }
    # 移除旧块（Get-Content -Raw 对空文件可能返回 $null，先转字符串再替换）
    $content = [regex]::Replace([string]$content, "(?s)# === ProxySwitch begin ===.*?# === ProxySwitch end ===\r?\n?", "")
    if ($content.Trim()) { $content = $content.TrimEnd() + "`r`n`r`n" }
    Set-Content $pf ($content + $block + "`r`n") -Encoding UTF8
    Write-Host "已配置 profile: $pf"
}

Write-Host ""
Write-Host "ProxySwitch 安装完成！请重开终端后使用："
Write-Host "  proxy set http://127.0.0.1:7890   (可选，设置代理地址)"
Write-Host "  proxy on                          (开启代理)"
Write-Host "  proxy status                      (查看状态)"
