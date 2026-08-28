@{
    RootModule           = 'ProxySwitch.psm1'
    ModuleVersion        = '1.0.6'
    GUID                 = '3f8a2c1e-9b4d-4f6a-8c2e-1d5b7a9e3c0f'
    Author               = 'proxy-switch'
    CompanyName          = ''
    Copyright            = '(c) 2026 proxy-switch'
    Description          = '终端与 Git 代理一键切换：proxy on/off/status/set/set-auth/edit/test，支持 scoop 安装。'
    PowerShellVersion    = '5.1'
    FunctionsToExport    = @('proxy')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags       = @('proxy', 'git', 'windows', 'terminal', 'scoop')
            ProjectUri = 'https://github.com/YOURNAME/proxy-switch'
        }
    }
}





