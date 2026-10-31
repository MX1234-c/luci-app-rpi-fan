# 1.1.0 软件包验证 · 2026-10-31

## 官方 SDK 与发布

[r2 构建和发布任务](https://github.com/MX1234-c/luci-app-rpi-fan/actions/runs/41181546833) 的 build、release 均成功。
使用固定 SHA256 校验的官方 OpenWrt 25.12.6 bcm27xx/bcm2710 SDK。
真实 `apk mkpkg` 日志确认版本 `1.1.0-r2`、架构 `noarch`。

发布 APK：`luci-app-rpi-fan-1.1.0-r2.apk`，5488 bytes。
SHA256：`51f0f253dd0a44438dc92e6d726d2925b27924ca82b9fb58c7b6f842d6481624`。
附件已重新下载并校验，不是将源码 tar.gz 改后缀。

## 实机

设备：树莓派 3B+、OpenWrt 25.12.6、内核 6.12.112、GPIO18/PWM0、1 kHz。

- 控制器后台 0/50/100% 目标与 PWM 读回一致。
- LuCI 保存手动 50% 生效；恢复自动模式后状态正常。
- stop 后等待 3 秒，duty_cycle=1000000、enable=1。
- 实际掉电重启后修复保留、服务自启。
- APK r1 从本项目脚本部署直接安装成功，只新增本插件。
- 安装前后原 UCI 配置逐字节一致，默认配置另存 `.apk-new`。
- 安装后 ubus：running=true、reason=normal、pwm_ok=true。

r2 只修正 noarch/项目 URL 元数据，控制器与 r1 相同。
r1 → r2 实机升级成功（apk 输出 1.1.0-r1 -> 1.1.0-r2），SHA256 校验通过。
升级后与安装前备份 cmp 一致；ubus running=true、reason=normal、pwm_ok=true、target=actual=0。
procd 确认进程运行，开机启动 enabled 检查通过。
**APK 卸载尚未实机验证；升级测试不能代替卸载测试。**
其他硬件、GPIO、固件版本、风扇真实 RPM、长期运行未经验证。

## 自动测试和审查

CI 已通过 `python3 tests/integration.py`、`python3 tests/package.py`、`node tests/luci.js`。
覆盖温控边界/滞回、手动/关闭/故障优先级、PWM 输入和读回、错误传播、
六种进程场景、EXIT/TERM 停机、状态新鲜度、LuCI 表单与隐藏配置保留。
安装钩子执行 live/offline 两种分支，服务命令用替身验证；offline 不操作主机服务。

独立审查发现升级可能继续运行旧核心，已增加 postinst restart 和回归测试。
发布标签包含 PKG_RELEASE；已发布附件不覆盖。
SDK 真实日志发现全局 PKGARCH 被默认值覆盖，已移入 Package 定义，r2 确认 noarch。
1.0.x 的开发与回归历史见 TEST-REPORT.md。

本包未配置可信分发签名，安装方式及迁移/卸载见 docs/INSTALL.md。
