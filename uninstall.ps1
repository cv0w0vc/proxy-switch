# ============================================================================
#  ProxySwitch 卸载脚本（scoop uninstaller 调用，也可手动运行）
#
#  清理内容:
#    1. 删除模块目录（PS7 + PS5.1 的 Documents\...\Modules\ProxySwitch）
#    2. 从两个 $PROFILE 移除 ProxySwitch 引导块（若文件变空则删除文件）
#    3. 尝试从当前会话卸载
# ============================================================================
$ErrorActionPreference = "Continue"

$ModuleName = "ProxySwitch"
$DocsDir    = [Environment]::GetFolderPath("MyDocuments")

# 1. 删除模块目录
$ModuleDirs = @(
    (Join-Path $DocsDir "PowerShell\Modules\$ModuleName"),
    (Join-Path $DocsDir "WindowsPowerShell\Modules\$ModuleName")
)
foreach ($dir in $ModuleDirs) {
    if (Test-Path $dir) {
        Remove-Item $dir -Recurse -Force
        Write-Host "已删除模块目录: $dir"
    }
}

# 2. 从 $PROFILE 移除引导块（只删标记块，保留其他内容）
$ProfileFiles = @(
    (Join-Path $DocsDir "PowerShell\Microsoft.PowerShell_profile.ps1"),
    (Join-Path $DocsDir "WindowsPowerShell\Microsoft.PowerShell_profile.ps1")
)
foreach ($pf in $ProfileFiles) {
    if (Test-Path $pf) {
        $content = [string](Get-Content $pf -Raw)
        $new = [regex]::Replace($content, "(?s)# === ProxySwitch begin ===.*?# === ProxySwitch end ===\r?\n?", "")
        if ($new.Trim()) {
            Set-Content $pf $new -Encoding UTF8
            Write-Host "已清理 profile: $pf"
        }
        else {
            Remove-Item $pf -Force
            Write-Host "profile 已空，删除文件: $pf"
        }
    }
}

# 3. 尝试从当前会话卸载（如果有）
Remove-Module $ModuleName -ErrorAction SilentlyContinue
Remove-Item function:proxy -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "ProxySwitch 已卸载。请重开终端生效。"
