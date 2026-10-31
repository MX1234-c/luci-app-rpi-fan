# APK 安装、升级和卸载

适用：树莓派 3B+，OpenWrt 25.12.6，GPIO18 硬件 PWM0。
这是独立第三方插件，不是 OpenWrt 官方仓库软件。不要安装到尚未适配的其他硬件。

## 1. 确认 PWM 已启用

```sh
cat /etc/openwrt_release
ls -l /sys/class/pwm/pwmchip0
cat /sys/class/thermal/thermal_zone0/temp
```

若没有 pwmchip0，先检查启动分区上的 config.txt 和 overlays/pwm.dtbo。
树莓派官方 overlay 使用 `dtoverlay=pwm,pin=18,func=2` 选择 GPIO18。
请在现有 PWM/audio 配置基础上检查，避免叠加冲突 overlay；改启动配置后需要重启。
包不会替你修改启动分区。GPIO18 是控制信号，电机必须使用独立电源及适当驱动，不能由 GPIO 供电。
如果启用了内核 pwm-fan 等其他消费者，本插件不能同时接管同一通道。

## 2. 下载发布附件

打开 https://github.com/MX1234-c/luci-app-rpi-fan/releases ，选择对应版本。
下载 `.apk` 和 `SHA256SUMS`，上传至树莓派 `/tmp`，然后在 SSH 终端执行：

```sh
cd /tmp
sha256sum -c SHA256SUMS
apk update
apk add luci-base rpcd uci jsonfilter
```

必须看到 APK 校验 `OK`，再继续。以下命令中的文件名替换为实际下载的 APK 文件名：

```sh
apk add --allow-untrusted /tmp/luci-app-rpi-fan-实际版本.apk
/etc/init.d/rpi-fan enable
/etc/init.d/rpi-fan restart
sleep 3
ubus call rpi-fan status
```

`--allow-untrusted` 仅用于你核对过来源及 SHA256 的本地第三方 APK；不添加全局信任或修改系统安全设置。
无需安装 git、Python 或 Node.js。重新登录 LuCI，进入“服务 → 树莓派风扇”。

## 3. 升级

先保存配置备份：

```sh
cp /etc/config/rpi-fan /root/rpi-fan-config.backup
```

下载新版本和校验文件，校验通过后再次 `apk add --allow-untrusted /tmp/新版本.apk`。
安装钩子会重启控制器，确保新脚本被载入；升级完成后再次检查 `ubus call rpi-fan status`。
UCI 配置声明为 conffile；检查并保留已有配置，关注可能产生的 `.apk-new` 文件。
不要同时执行旧的 `install.sh` 和 APK 升级。

## 4. 从 install.sh 旧版迁移

先备份 `/etc/config/rpi-fan`。旧脚本部署的文件尚未受 APK 管理。
已在本项目原始脚本版本验证可直接安装 APK 接管，原 UCI 配置保留，默认配置另存为 `.apk-new`。
先运行 `apk add --simulate --allow-untrusted /tmp/实际文件.apk` 检查事务，确认只安装本插件再实际安装。
如果你的旧版文件来自其他 fork 并发生冲突，按旧版 README 的“直接部署卸载”清单移除程序文件并保留配置，
再安装 APK，恢复配置，执行 enable 和 restart。不要使用全局 `--force-overwrite` 绕过不明文件冲突。
停止服务会尝试保持全速；迁移期间人工关注散热，完成后检查 `pwm_ok=true`。

## 5. 卸载

```sh
apk del luci-app-rpi-fan
/etc/init.d/rpcd restart
```

卸载会停止服务并取消自启。停止服务时会尝试保留全速输出，但下次重启后不再受本插件管理。
卸载前应准备其他散热方案。需要保留配置时请预先备份，不依赖包管理器的残留行为。

## 使用与排查

默认自动温控：45°C 停止，50°C 启动，70°C 全速，80°C 安全强制全速。
温度读取异常/配置错误时全速；正常网页关闭输出 0%，但超温保护仍有效。
服务退出处理可能需要约 2 秒；检查退出全速时，stop 后等待 3 秒再读取 sysfs。
PWM 占空比不是实际 RPM，软件不能检测风扇堵转；断电/强杀/硬件故障不受退出保护保证。

```sh
ubus call rpi-fan status
logread -e rpi-fan
uci show rpi-fan
/etc/init.d/rpi-fan enabled && echo AUTOSTART_OK
```

GPIO 更换需要正确的设备树 pinmux；本版本只支持已验证的 GPIO18。
其他 GPIO 功能按“无法可靠实现就舍弃”的要求不提供，避免界面显示成功但没有实际输出。
