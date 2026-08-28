# AGENTS.md

编码 agent 在本仓库工作时应遵循的指引。本文件随仓库分发，所有协作者与 agent 共同遵守。

## 项目

- **ProxySwitch**：终端与 Git 代理一键切换（Windows / PowerShell 模块）。
- 模块源码在 `src/`（`ProxySwitch.psd1` + `ProxySwitch.psm1`）。
- `install.ps1` / `uninstall.ps1`：安装 / 清理（模块目录 + `$PROFILE` 引导块）。
- `release.ps1`：一键发布（patch 版本 +1 → tag → 下载源码包 → 更新 manifest）。
- `proxy-switch.json`：scoop manifest，记录 version / url / hash / extract_dir。

## 代码提交规则

- **语言**：提交信息用英文（与仓库历史一致），小写、动词开头：`add` / `fix` / `update` / `remove` / `refactor`。
- **风格**：功能类用裸动词，如 `add uninstaller support`；发布前准备用 `chore:` 前缀，如 `chore: pre-release 1.0.2`；`release vX.Y.Z` 专用于 `release.ps1` 生成的发布提交。
- **粒度**：一条提交只做一件事，不把无关改动混进同一个提交。
- **成对同步**：改动必须带上配套文件——改模块行为时同步 `install.ps1` / `uninstall.ps1`；发布时同步更新 `proxy-switch.json`（version / url / hash / extract_dir）与 `src/ProxySwitch.psd1` 的 ModuleVersion。
- **发布流程**：不要手工创建 `release vX.Y.Z` 提交或 tag，统一交给 `release.ps1`（它负责 patch 版本、打 tag、推送、更新 manifest 并提交）。
