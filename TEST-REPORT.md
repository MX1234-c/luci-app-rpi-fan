# 验证记录 · 2026-10-31

测试环境：Windows，Python，Git Bash，dash，Node.js。
不连接真实 GPIO，不修改主机服务，控制进程测试在临时文件中执行。

已执行并通过：

```text
python tests/integration.py
PASS: control boundaries, ramp, hysteresis, off, manual, fail-safe, validation
PASS: PWM normalize, zero, full, input rejection and I/O failure
PASS: shell syntax and JSON manifests
PASS: six daemon scenarios, status JSON and full-speed EXIT/TERM shutdown
PASS: rpcd executable signature
PASS: rpcd fresh, future and malformed timestamp handling (jsonfilter fixture)

node tests/luci.js
PASS: LuCI form/status contract and cross-field validation

dash tests/control.sh
dash tests/pwm.sh
PASS (both; run from Git Bash so Unix utilities are on PATH)
```

测试开发中先观察到失败，再修复并重跑：

- 初始控制测试因控制库尚未实现而失败。
- PWM 测试暴露 1000000 ns 七位数被误拒绝的问题。
- LuCI 回归测试暴露切换模式时隐藏字段未 retain 的问题。
- LuCI 回归测试暴露占空比缺少严格整数验证的问题。

独立审查覆盖控制器、procd、UCI、rpcd 协议、ACL、LuCI、部署和打包配方。
两项审查发现已修复；官方 25.12 form.js 的隐藏字段语义已核对。

明确未验证：

- 官方 SDK 编译及 APK 安装/卸载。
- 真实 OpenWrt 的 UCI 提交、procd reload、rpcd ACL 和 LuCI 浏览器交互。
- 树莓派 GPIO 电气波形、最低起转占空比、温度曲线和实际重启/关机。

上述目标环境验收步骤见 README.zh-CN.md；tests/on-device.sh 是只读检查脚本。
最终归档由交付打包步骤逐文件核对内容、LF 行尾、路径和执行权限，并生成 SHA256。
