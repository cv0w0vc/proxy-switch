# ============================================================================
#  ProxySwitch - 终端与 Git 代理一键切换
#
#  命令: proxy on|off|status|set|set-auth|unset-auth|edit|config|test
#  配置: ~/.config/proxy-switch/config.json
#  依赖: Git（可选，配置 gitProxy=false 时无需）
# ============================================================================

$script:ConfigPath = Join-Path $env:USERPROFILE ".config\proxy-switch\config.json"

# ---------------- 配置读写 ----------------

function Get-ProxyConfig {
    if (-not (Test-Path $script:ConfigPath)) {
        return @{
            proxyAddr      = "http://127.0.0.1:7890"
            authUser       = ""
            authPass       = ""
            gitProxy       = $true
        }
    }
    $raw = Get-Content -Path $script:ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
    return @{
        proxyAddr      = if ($raw.proxyAddr) { [string]$raw.proxyAddr } else { "http://127.0.0.1:7890" }
        authUser       = if ($null -ne $raw.authUser) { [string]$raw.authUser } else { "" }
        authPass       = if ($null -ne $raw.authPass) { [string]$raw.authPass } else { "" }
        gitProxy       = if ($null -ne $raw.gitProxy) { [bool]$raw.gitProxy } else { $true }
    }
}

function Save-ProxyConfig {
    param([hashtable]$Config)
    $dir = Split-Path $script:ConfigPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
    $Config | ConvertTo-Json | Set-Content -Path $script:ConfigPath -Encoding UTF8
}

# ---------------- 地址 ----------------

function Get-EffectiveProxyAddr {
    $cfg = Get-ProxyConfig
    if ($cfg.authUser) {
        if ($cfg.proxyAddr -match '^(https?)://(.+)$') {
            $user = [uri]::EscapeDataString($cfg.authUser)
            $pass = [uri]::EscapeDataString($cfg.authPass)
            return ($Matches[1] + "://" + $user + ":" + $pass + "@" + $Matches[2])
        }
    }
    return $cfg.proxyAddr
}

function Get-MaskedProxyAddr {
    $addr = Get-EffectiveProxyAddr
    return ($addr -replace '^(https?://[^:/]+):[^@]+@', '$1:****@')
}

# ---------------- 状态开关 ----------------

function Set-ProxyState {
    param([string]$State, [string]$Scope = "all", [switch]$Quiet)

    if ($Scope -in "all", "env") {
        if ($State -eq "on") {
            $addr = Get-EffectiveProxyAddr
            $env:HTTP_PROXY  = $addr
            $env:HTTPS_PROXY = $addr
            $env:ALL_PROXY   = $addr
            $env:NO_PROXY    = "localhost,127.0.0.1,::1"
        }
        else {
            Remove-Item Env:HTTP_PROXY, Env:HTTPS_PROXY, Env:ALL_PROXY, Env:NO_PROXY -ErrorAction SilentlyContinue
        }
    }

    $cfg = Get-ProxyConfig
    if ($Scope -in "all", "git" -and $cfg.gitProxy -and (Get-Command git -ErrorAction SilentlyContinue)) {
        if ($State -eq "on") {
            $addr = Get-EffectiveProxyAddr
            git config --global http.proxy  $addr
            git config --global https.proxy $addr
        }
        else {
            git config --global --unset http.proxy  2>$null
            git config --global --unset https.proxy 2>$null
        }
    }

    if (-not $Quiet) {
        if ($State -eq "on") {
            Write-Host ("代理已开启: " + (Get-MaskedProxyAddr)) -ForegroundColor Green
        }
        else {
            Write-Host "代理已关闭" -ForegroundColor Yellow
        }
    }
}

function Show-ProxyStatus {
    $cfg = Get-ProxyConfig
    Write-Host "=== ProxySwitch 状态 ==="
    Write-Host ("代理地址 : " + (Get-MaskedProxyAddr))
    Write-Host ("认证     : " + $(if ($cfg.authUser) { "已启用 ($($cfg.authUser))" } else { "无" }))
    Write-Host ("Git 管理 : " + $(if ($cfg.gitProxy) { "随开关一起" } else { "不管理" }))
    Write-Host ""
    $envHttp  = [bool]$env:HTTP_PROXY
    $envHttps = [bool]$env:HTTPS_PROXY
    $gitHttp  = $false
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $gitHttp = [bool](git config --global --get http.proxy 2>$null)
    }

    foreach ($item in @(
        @{ Label = "终端 HTTP_PROXY "; Value = $envHttp  },
        @{ Label = "终端 HTTPS_PROXY"; Value = $envHttps },
        @{ Label = "Git  http.proxy "; Value = $gitHttp  }
    )) {
        Write-Host ($item.Label + " : ") -NoNewline
        if ($item.Value) {
            Write-Host "true" -ForegroundColor Green
        }
        else {
            Write-Host "false" -ForegroundColor DarkGray
        }
    }
}

# ---------------- 配置命令 ----------------

function Set-ProxyAddress {
    param([string]$Address)
    if (-not $Address) {
        throw "用法: proxy set <地址>  例如: proxy set http://127.0.0.1:7890"
    }
    if ($Address -notmatch '^https?://[^\s/]+$') {
        throw "地址格式不正确，示例: http://127.0.0.1:7890"
    }
    $cfg = Get-ProxyConfig
    $cfg.proxyAddr = $Address
    Save-ProxyConfig $cfg
    Write-Host ("已保存代理地址: " + $Address) -ForegroundColor Green
}

function Set-ProxyAuth {
    param([string]$User)
    if (-not $User) {
        throw "用法: proxy set-auth <用户名>（密码将交互式输入，不会显示）"
    }
    $secure = Read-Host "请输入密码" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $pass = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
    $cfg = Get-ProxyConfig
    $cfg.authUser = $User
    $cfg.authPass = $pass
    Save-ProxyConfig $cfg
    Write-Host ("已保存认证信息（用户: " + $User + "）") -ForegroundColor Green
}

function Clear-ProxyAuth {
    $cfg = Get-ProxyConfig
    $cfg.authUser = ""
    $cfg.authPass = ""
    Save-ProxyConfig $cfg
    Write-Host "已清除认证信息" -ForegroundColor Yellow
}

function Show-ProxyConfig {
    $cfg = Get-ProxyConfig
    Write-Host "=== 配置文件: $script:ConfigPath ==="
    Write-Host ("代理地址 : " + (Get-MaskedProxyAddr))
    Write-Host ("认证用户 : " + $(if ($cfg.authUser) { $cfg.authUser } else { "(无)" }))
    Write-Host ("Git 管理 : " + $cfg.gitProxy)
}

function Open-ProxyConfig {
    $null = Get-ProxyConfig
    Save-ProxyConfig (Get-ProxyConfig)
    $editor = $env:EDITOR
    if (-not $editor) { $editor = "notepad" }
    & $editor $script:ConfigPath
}

function Test-ProxyConnection {
    $cfg = Get-ProxyConfig
    if (-not $cfg.proxyAddr) { throw "未配置代理地址" }

    $target = "https://www.google.com"
    $webArgs = @{
        Uri            = $target
        Proxy          = $cfg.proxyAddr
        TimeoutSec     = 10
        UseBasicParsing = $true
    }
    if ($cfg.authUser) {
        $sec = ConvertTo-SecureString $cfg.authPass -AsPlainText -Force
        $webArgs.ProxyCredential = New-Object System.Management.Automation.PSCredential($cfg.authUser, $sec)
    }

    try {
        $r = Invoke-WebRequest @webArgs
        Write-Host ("代理可用: HTTP " + [int]$r.StatusCode + " (" + $target + ")") -ForegroundColor Green
    }
    catch {
        # 识别 407：优先取异常链里的状态码，兜底匹配消息文本（兼容 PS 7 / PS 5.1）
        $status = $null
        $ex = $_.Exception
        while ($null -ne $ex) {
            if ($ex.Response) { $status = [int]$ex.Response.StatusCode; break }
            $ex = $ex.InnerException
        }
        if (-not $status -and $_.Exception.Message -match '407') { $status = 407 }

        if ($status -eq 407) {
            Write-Host "代理测试失败: 代理要求认证 (407)，请运行 proxy set-auth 检查认证配置" -ForegroundColor Red
        }
        else {
            Write-Host ("代理测试失败: 无法通过代理访问 " + $target + "，请检查代理地址或网络: " + $_.Exception.Message) -ForegroundColor Red
        }
    }
}

# ---------------- 入口 ----------------

function proxy {
    param(
        [Parameter(Position = 0)][string]$Action = "status",
        [Parameter(Position = 1)][string]$Target = "",
        [switch]$Git,
        [switch]$Env,
        [switch]$Quiet
    )

    # 兼容旧写法: proxy git on / proxy env off
    $scope = "all"
    if ($Action -in "git", "env") {
        $scope = $Action
        $Action = if ($Target) { $Target } else { "on" }
    }
    if ($Git) { $scope = "git" }
    if ($Env) { $scope = "env" }

    switch ($Action.ToLower()) {
        "on"         { Set-ProxyState -State on  -Scope $scope -Quiet:$Quiet }
        "off"        { Set-ProxyState -State off -Scope $scope -Quiet:$Quiet }
        "status"     { Show-ProxyStatus }
        "set"        { Set-ProxyAddress $Target }
        "set-auth"   { Set-ProxyAuth $Target }
        "unset-auth" { Clear-ProxyAuth }
        "edit"       { Open-ProxyConfig }
        "config"     { Show-ProxyConfig }
        "test"       { Test-ProxyConnection }
        "help"       { Show-ProxyHelp }
        default      { Write-Host "未知命令: $Action"; Show-ProxyHelp }
    }
}

function Show-ProxyHelp {
    Write-Host @"
ProxySwitch - 终端与 Git 代理一键切换

用法:
  proxy on | off [-git|-env]      开启/关闭代理（默认全部，可只开关 git 或终端）
  proxy git on | git off          旧写法，等价于 proxy on -git
  proxy status                    查看当前生效状态
  proxy set <地址>                 设置代理地址，如: proxy set http://127.0.0.1:7890
  proxy set-auth <用户名>          设置认证（密码交互输入）
  proxy unset-auth                清除认证
  proxy config                    查看配置文件
  proxy edit                      用编辑器打开配置文件
  proxy test                      测试代理连通性
"@
}

Export-ModuleMember -Function proxy
