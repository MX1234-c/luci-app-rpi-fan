# LuCI 树莓派 PWM 风扇控制

第三方 OpenWrt 插件，支持网页手动调速、自动温控、滞回、开关、阈值设置、状态显示和开机自启。

**支持范围：树莓派 3B+ · OpenWrt 25.12.6 · GPIO18 / PWM0 · 1 kHz。**
PWM 设备树 overlay 必须预先启用；本包不修改启动分区，不支持任意 GPIO 在线切换。
APK 的 noarch 表示文件是脚本和网页资源，不表示兼容任意硬件。

## 安装 APK

从 [Releases](https://github.com/MX1234-c/luci-app-rpi-fan/releases) 下载构建成功版本的 `.apk` 和 `SHA256SUMS`。
上传至树莓派 `/tmp`，校验后安装：

```sh
cd /tmp
sha256sum -c SHA256SUMS
apk add --allow-untrusted /tmp/luci-app-rpi-fan-实际版本.apk
```

文件名请替换为实际下载的版本。此包未配置可信分发签名，不属于 OpenWrt 官方软件源；
仅对核对过来源和 SHA256 的本地文件使用 `--allow-untrusted`。
重新登录 LuCI，打开 **服务 → 树莓派风扇**。

- [完整安装、升级、旧版迁移、卸载说明](docs/INSTALL.md)
- [版本发布说明](docs/RELEASE-NOTES.md)
- [软件包测试记录及验证范围](TEST-REPORT-1.1.0.md)
- [更新记录](CHANGELOG.md)
- [原始脚本部署说明](README.zh-CN.md)

## 运行行为

默认自动温控：50°C 启动，45°C 停止，70°C 全速，80°C 安全强制全速。
温度读取失败或配置无效时请求全速。网页关闭时正常输出 0%，超温保护仍然有效。
服务退出时尝试全速，执行 stop 后应等待约 3 秒再检查；断电或硬件故障无法保证输出。
风扇使用独立电源及适当的驱动电路；GPIO 只连接控制信号。PWM 读回值不等于实际 RPM。

## 构建与测试

源码使用标准 OpenWrt package Makefile。GitHub Actions 先运行测试，
再下载并校验固定的官方 25.12.6 bcm2710 SDK，构建 APK。
成功构建保存为 Actions artifact；main 分支新版本随后发布 Release。
已发布的版本附件不会被构建任务覆盖。

Linux 本地构建（需满足 OpenWrt SDK 的系统依赖）：

```sh
python3 tests/integration.py
python3 tests/package.py
node tests/luci.js
bash scripts/build-sdk.sh
```

脚本拒绝复用已有 `work/sdk`，避免混用旧 SDK；应使用新的源码副本重建。
构建产物在 `release/`。依赖软件源由 SDK 的 feeds 定义获取，重建时可能发生上游变化；
SDK 压缩包和 SHA256 已固定，不宣称所有依赖均达到位级可重复构建。

## 实机验证范围

控制器核心已在用户树莓派 3B+ 验证：PWM 0/50/100%、LuCI 保存手动 50%、
自动模式恢复、服务退出后全速、实际掉电重启后自启。
APK 本身的 SDK 构建和安装验证单独记录，不能以控制器测试代替软件包测试。
其他硬件、GPIO 和固件版本未经验证，不作兼容承诺。

MIT License。欢迎在 Issues 提交固件版本、硬件型号和去除敏感信息后的报错。
