# ProxySwitch

终端与 Git 代理一键切换（Windows / PowerShell）。

一条命令开关**终端代理**（环境变量）和 **Git 代理**（`git config`），支持认证、自动检测、配置命令化。

## 安装

### 方式一：scoop（推荐）

```powershell
scoop install proxy-switch
```

安装器会自动：
1. 安装模块到 `Documents\PowerShell\Modules\ProxySwitch`（PS7 与 PS5.1 都装）
2. 在 `$PROFILE` 追加 `Import-Module ProxySwitch` 和 `proxy autodetect`

**重开终端**后即可使用。

### 方式二：手动

```powershell
# 克隆/解压本项目后，运行安装脚本
.\install.ps1
```

## 卸载

```powershell
scoop uninstall proxy-switch
```

scoop 卸载时会自动运行 `uninstall.ps1`，清理：

1. 模块目录（PS7 与 PS5.1 的 `Documents\...\Modules\ProxySwitch`）
2. `$PROFILE` 中的 ProxySwitch 引导块（只删标记块，保留其他内容）

手动安装的也可以直接运行 `.\uninstall.ps1` 完成同样清理。

## 使用

```powershell
proxy on | off [-git|-env]      开启/关闭代理（默认全部，可只开关 git 或终端）
proxy git on | git off          旧写法，等价于 proxy on -git
proxy status                    查看当前生效状态
proxy set <地址>                 设置代理地址，如: proxy set http://127.0.0.1:7890
proxy set-auth <用户名>          设置认证（密码交互式输入，不回显）
proxy unset-auth                清除认证
proxy config                    查看配置
proxy edit                      用编辑器打开配置文件
proxy test                      测试代理连通性
proxy autodetect                检测本地代理端口并自动开启（安装后已自动调用）
```

## 配置

配置文件：`~/.config/proxy-switch/config.json`（用 `proxy edit` 打开，或命令修改）

| 字段 | 默认值 | 说明 |
|------|--------|------|
| `proxyAddr` | `http://127.0.0.1:7890` | 代理地址 |
| `authUser` / `authPass` | 空 | 认证信息（`proxy set-auth` 写入，显示时打码） |
| `autoDetectPort` | `7890` | 新终端启动时检测该端口，有代理客户端在跑就自动开启；`0` 关闭 |
| `gitProxy` | `true` | 是否把 Git 代理一起开关 |

> 代理地址中的特殊字符（`@`、`:`、`/`）需要 URL 编码，`proxy set-auth` 已自动处理。

## 说明

- **终端代理**：设置当前会话的 `HTTP_PROXY` / `HTTPS_PROXY` / `ALL_PROXY` / `NO_PROXY`，只影响当前终端
- **Git 代理**：写入 `git config --global http.proxy` / `https.proxy`，全仓库生效
- 本地代理客户端（Clash / v2rayN 等）**不需要认证**，认证在客户端内部完成；仅直连远程认证代理时才需要 `proxy set-auth`
- 如果之前手动配置过旧版 `proxy` 函数，请从 `$PROFILE` 中删除旧函数（模块版会覆盖）

## 开发

```
proxy-switch/
├── src/
│   ├── ProxySwitch.psm1   # 模块主体（全部功能）
│   └── ProxySwitch.psd1   # 模块清单
├── install.ps1            # 安装脚本（scoop installer 调用）
├── uninstall.ps1          # 卸载脚本（scoop uninstaller 调用）
├── release.ps1            # 一键发布脚本（打包+算哈希+更新 manifest）
├── proxy-switch.json      # scoop manifest（含 installer/uninstaller）
└── README.md
```

发布新版本（一条命令）：

```powershell
.\release.ps1                # 自动 patch 版本 +1（1.0.1 -> 1.0.2）
.\release.ps1 -Version 1.1.0 # 指定版本
```

脚本自动完成：提交改动 → 打 tag → 推送 → 下载源码包 → 计算哈希 → 更新 `proxy-switch.json` 与 `ModuleVersion` → 推送 manifest。之后新电脑 `scoop update && scoop install proxy-switch` 即可。

## License

MIT
