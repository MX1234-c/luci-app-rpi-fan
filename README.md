# 树莓派 LuCI PWM 风扇控制

面向 Raspberry Pi 3B+ / OpenWrt 25.12.6，使用已验证的 GPIO18 硬件 PWM，固定周期 1000000 ns。

支持网页手动占空比、自动温控与滞回、开关与阈值配置、运行状态、procd 开机自启和停机全速保护。通过 UCI 保存配置，rpcd/ubus 提供只读状态。

- [中文安装与使用说明](README.zh-CN.md)
- [部署包](dist/luci-app-rpi-fan-1.0.1.tar.gz)
- [SHA256 校验](dist/SHA256SUMS.txt)
- [测试记录](TEST-REPORT.md)

**已通过本机模拟测试和静态审查；未进行树莓派实机验证或官方 SDK 编译。部署包是源码与安装脚本，不是预编译 APK。**

将部署包上传到树莓派后解压，在目录中执行 `sh install.sh`。详细依赖、安装、SDK 构建及卸载步骤见中文说明。

MIT License.
