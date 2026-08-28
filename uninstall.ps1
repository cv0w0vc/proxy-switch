# ============================================================================
#  ProxySwitch 卸载脚本（scoop uninstaller 调用，也可手动运行）
#
#  清理内容:
#    1. 清理运行时代理配置（git / npm / pip + 当前会话环境变量，内联实现，不依赖模块）
#    2. 删除模块目录（PS7 + PS5.1 的 Documents\...\Modules\ProxySwitch）
#    3. 从两个 $PROFILE 移除 ProxySwitch 引导块（若文件变空则删除文件）
#    4. 删除配置文件（~/.config/proxy-switch/config.json，含认证信息）
#    5. 尝试从当前会话卸载
# ============================================================================
$ErrorActionPreference = "Continue"

$ModuleName = "ProxySwitch"
$DocsDir    = [Environment]::GetFolderPath("MyDocuments")

# 1. 清理运行时代理配置（内联实现，不依赖模块是否存在）
if (Get-Command git -ErrorAction SilentlyContinue) {
    git config --global --unset http.proxy  2>$null
    git config --global --unset https.proxy 2>$null
}
if (Get-Command npm -ErrorAction SilentlyContinue) {
    npm config delete proxy       2>$null
    npm config delete https-proxy 2>$null
}
if (Get-Command pip -ErrorAction SilentlyContinue) {
    pip config unset global.proxy 2>$null
}
Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY, Env:ALL_PROXY, Env:NO_PROXY -ErrorAction SilentlyContinue
Write-Host "已清理运行时代理配置 (git / npm / pip / 环境变量)"

# 2. 删除模块目录
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

# 3. 从 $PROFILE 移除引导块（只删标记块，保留其他内容）
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

# 4. 删除配置文件（含认证信息，目录空则一并删除）
$ConfigDir  = Join-Path $env:USERPROFILE ".config\proxy-switch"
$ConfigFile = Join-Path $ConfigDir "config.json"
if (Test-Path $ConfigFile) {
    Remove-Item $ConfigFile -Force
    Write-Host "已删除配置文件: $ConfigFile"
}
if (Test-Path $ConfigDir -and -not (Get-ChildItem $ConfigDir -Force | Select-Object -First 1)) {
    Remove-Item $ConfigDir -Force
    Write-Host "已删除配置目录: $ConfigDir"
}

# 5. 尝试从当前会话卸载（如果有）
Remove-Module $ModuleName -ErrorAction SilentlyContinue
Remove-Item function:proxy -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "ProxySwitch 已完全卸载。请重开终端生效。"
