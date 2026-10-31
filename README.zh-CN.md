# 树莓派 3B+ LuCI 硬件 PWM 风扇控制

版本 1.0.1。面向 OpenWrt 25.12.6；提供可直接部署的源文件和官方 SDK 软件包配方。
**此交付不是已编译 APK，也未在你的树莓派上运行过。**

## 已固定的硬件接口

- GPIO18（BCM 编号，物理引脚 12），PWM0。
- `/sys/class/pwm/pwmchip0/pwm0`，周期 `1000000 ns`，即 1 kHz。
- 正常极性：`normal`；占空比 `0..100%` 对应 `0..1000000 ns`。
- 温度来源 `/sys/class/thermal/thermal_zone0/temp`，单位毫摄氏度。

沿用你已验证可用的 PWM 和接线，不改设备树或引脚复用。安装前停用此前的风扇脚本、rc.local PWM 命令等，确保只有本服务写 PWM。GPIO18 应连接适当的控制输入或驱动电路，不能用 GPIO 给风扇电机供电。此版本不支持转速反馈，网页显示的是 PWM 读回值。

## 直接部署（推荐先用此方式）

OpenWrt 25.12 已改用 APK，不要照旧教程执行 opkg。
在树莓派 SSH 终端检查并安装依赖（已有 LuCI 的设备通常已满足）：

```sh
cat /etc/openwrt_release
ubus call system board
ls -l /sys/class/pwm/pwmchip0
cat /sys/class/thermal/thermal_zone0/temp
apk update
apk add luci-base rpcd uci jsonfilter
```

将交付的 `luci-app-rpi-fan-1.0.1.tar.gz` 上传到树莓派 `/tmp/`。
例如在电脑上使用 scp；地址换成你的路由器地址：

```sh
scp luci-app-rpi-fan-1.0.1.tar.gz root@192.168.1.1:/tmp/
```

然后在树莓派执行：

```sh
cd /tmp
tar -xzf luci-app-rpi-fan-1.0.1.tar.gz
cd luci-app-rpi-fan
sh install.sh
sleep 3
ubus -v list rpi-fan
ubus call rpi-fan status
logread -e rpi-fan
```

安装器会检查依赖和 PWM 芯片、备份将覆盖的已有文件、保留已有 UCI 配置、启用开机自启并启动服务。备份路径会打印到终端，通常为 `/root/rpi-fan-backup-日期-进程号.tar.gz`。它会重启 rpcd，请重新登录 LuCI。

进入 **服务 → 树莓派风扇**，可调整开关、手动/自动模式、占空比、温度阈值。点击 **保存并应用** 后约 2 秒生效；从停止状态启动可能多用 1 秒全速助启动。状态每 2 秒刷新。若菜单未出现，退出重新登录并强制刷新页面，确认 `ubus -v list rpi-fan` 能找到接口。

## 默认行为与安全含义

默认开机自动运行，风扇开启、自动模式，最低占空比 40%。
CPU 温度达到 50°C 开始转动；启动后温度降到 45°C 才停止，避免在启动点反复启停。
50–70°C 之间从 40% 线性提高至 100%，70°C 及以上全速。
停止后再次启动时先全速运行 1 秒，再进入目标占空比；最低占空比需按你的风扇实际起转能力调整。

安全优先级从高到低：

1. 配置缺失/无效或温度不可读、非整数、超出 0..150°C：全速。
2. 温度达到安全阈值（默认 80°C）：全速，包括手动和关闭状态。
3. 网页关闭：0%；手动模式：指定占空比；自动模式：上述温控规则。

必须满足 `停止温度 < 启动温度 < 全速温度 < 安全温度`。所有阈值均为整数摄氏度。
停止温度允许 0..100，启动 1..110，全速 2..115，安全阈值 3..120。
手动占空比 0..100，自动最低占空比 1..100；整数不接受前导零。
不合理阈值虽能通过 SSH 写入 UCI，控制器仍会拒绝并进入全速保护。

**网页关闭与停止服务不同：** 网页关闭在正常温度下输出 0%；执行服务 stop/restart、系统正常关机时，退出处理会尝试输出 100%，保留 PWM 导出与使能状态，避免软件退出后风扇停止散热。关机最终引脚状态由内核和供电决定。掉电、SIGKILL、硬件故障或进程永久卡死时，软件不能保证全速；进程崩溃由 procd 约 5 秒后重启，但 PWM 可能暂时保留上一输出。

PWM 写入失败时状态为 `pwm_error`，尝试全速并每 2 秒重试；失败不会伪装成控制成功。此保护不等于风扇实际在转动，没有转速传感器无法确认机械状态。出现 PWM 异常时请直接检查散热与硬件。

## UCI 与服务命令

```sh
# 手动 50%
uci set rpi-fan.main.enabled='1'
uci set rpi-fan.main.mode='manual'
uci set rpi-fan.main.manual='50'
uci commit rpi-fan
/etc/init.d/rpi-fan reload

# 回到自动模式
uci set rpi-fan.main.mode='auto'
uci commit rpi-fan
/etc/init.d/rpi-fan reload

# 正常温度下关闭风扇（仍保留超温保护）
uci set rpi-fan.main.enabled='0'
uci commit rpi-fan
/etc/init.d/rpi-fan reload

# 服务与开机自启
/etc/init.d/rpi-fan enable
/etc/init.d/rpi-fan enabled && echo '开机自启已启用'
/etc/init.d/rpi-fan restart
/etc/init.d/rpi-fan stop
# 取消自启需明确执行 disable；下次开机将不再提供温控保护
# /etc/init.d/rpi-fan disable
```

配置文件 `/etc/config/rpi-fan`，固定命名节 `config fan 'main'`。
选项 `enabled mode manual minimum stop start full critical` 与网页对应。
服务每轮重新加载 UCI；CLI 暂存配置也可能被 UCI 工具读入，因此修改完应立即 commit，避免长时间停留在不完整的暂存状态。网页会话的暂存配置由 rpcd 隔离。

`ubus call rpi-fan status` 返回：`running`、开机后秒数 `updated`、毫摄氏度 `temperature`（失败为 null）、`target`、`actual`、`reason` 和 `pwm_ok`。
状态超过 10 秒不更新或文件不存在时仅返回 `{"running":false}`，含义是服务未运行或失去更新。
`actual` 是 sysfs 读回占空比，不是风扇转速；`pwm_ok=false` 表示本轮写入出现异常。

## 官方 SDK 构建 APK

Windows 本地测试不等于 SDK 编译。本交付没有运行 SDK；以下命令需在 Linux 或合适的 WSL Linux 环境执行。
使用 OpenWrt 官方 **25.12.6 / bcm27xx / bcm2710** SDK，先核对目标设备 `ubus call system board` 的 target。若你的固件是第三方构建，应使用其匹配的 SDK 与软件源。

官方下载目录：
[OpenWrt 25.12.6 bcm2710](https://downloads.openwrt.org/releases/25.12.6/targets/bcm27xx/bcm2710/)。
对应 SDK 文件名为 `openwrt-sdk-25.12.6-bcm27xx-bcm2710_gcc-14.3.0_musl.Linux-x86_64.tar.zst`。
下载后按官方目录中的 SHA256 校验，再解压。

在 SDK 根目录执行（源目录换成你解压交付包的位置）：

```sh
./scripts/feeds update -a
./scripts/feeds install -a
cp -R /path/to/luci-app-rpi-fan package/luci-app-rpi-fan
make defconfig
make package/luci-app-rpi-fan/compile V=s
find bin -name '*rpi-fan*.apk'
```

如需交互选择，可用 `make menuconfig` 在 LuCI → Applications 中选择 `luci-app-rpi-fan` 为 M。
将生成的 APK 上传到树莓派，按自己的签名信任设置安装。仅对你核对并自行构建的未签名包使用：

```sh
apk add --allow-untrusted /tmp/luci-app-rpi-fan-实际版本.apk
/etc/init.d/rpcd restart
/etc/init.d/rpi-fan enable
/etc/init.d/rpi-fan restart
```

生产分发应使用自己的签名和可信软件源。不要给 tar.gz 改后缀冒充 APK。
直接部署和 APK 管理不要混用；需要转换时先按下方卸载文件，但保留配置，再安装 APK。
包声明 `/etc/config/rpi-fan` 为配置文件；升级时应检查 APK 是否生成新的配置候选文件。

## 测试与实机验收

开发机测试：

```sh
python tests/integration.py
node tests/luci.js
```

需要 Python 3.10+、POSIX shell/bash、Node.js。Windows 默认使用 `D:/Program Files/Git/bin/bash.exe`，可通过 `BASH_EXE` 指定 Git Bash 路径。
控制逻辑测试覆盖边界、滞回、线性调速、关闭与手动、故障/超温优先级、整数输入校验。
模拟 sysfs 测试覆盖周期和极性归一化、0/50/100%、非法输入拒绝和写入失败。
进程测试在临时文件中运行真实控制循环，模拟 UCI 和 sysfs，覆盖六种状态、状态 JSON 与退出全速。
LuCI 测试使用最小契约替身检查页面逻辑，**不等于在真实 LuCI 浏览器上验证**。

树莓派安装后执行只读检查：

```sh
sh tests/on-device.sh
```

然后在散热可控、温度正常时逐项验收：

1. 网页手动 50%，sysfs `period=1000000`、`duty_cycle=500000`、`enable=1`，风扇实际运转。
2. 切换自动，再切回手动，`uci show rpi-fan` 中 manual 与 minimum 不应丢失。
3. 网页关闭，正常温度下 duty 为 0；再次开启可观察到 1 秒助启动。
4. 自动模式在自然温度变化时核对启动、停止滞回和升速；不要为测试故意让 CPU 过热。
5. 如需验证超温覆盖，在当前温度允许时临时设低阈值，并保持大小关系，观察 `reason=critical` 后立即恢复。传感器失效/异常输入已由模拟测试覆盖，不要破坏真实 thermal sysfs。
6. 执行 stop，检查 duty 为 1000000、enable 为 1；随后 restart。
7. 重启设备，再检查服务自启、ubus 状态、网页状态与 PWM。此步骤由你执行；本交付未声称已验证。

排查：`logread -e rpi-fan`；`ubus -v list rpi-fan`；`uci show rpi-fan`；查看 pwm0 的 period/duty_cycle/enable/polarity。
已有 pwm0 导出没关系，服务会接管；如果被其他内核消费者占用或 overlay 不正确，应先解决设备树与驱动问题。

## 卸载与回退

APK 安装使用 `apk del luci-app-rpi-fan`。直接部署的版本可运行：

```sh
/etc/init.d/rpi-fan stop
/etc/init.d/rpi-fan disable
rm -f /etc/init.d/rpi-fan /usr/sbin/rpi-fand /usr/lib/rpi-fan/control.sh
rm -f /usr/libexec/rpcd/rpi-fan
rm -f /usr/share/luci/menu.d/luci-app-rpi-fan.json
rm -f /usr/share/rpcd/acl.d/luci-app-rpi-fan.json
rm -f /www/luci-static/resources/view/rpi-fan.js
/etc/init.d/rpcd restart
```

配置默认保留。卸载后 PWM 会保留停机全速，但下一次开机不会有本服务管理，需要恢复原有控制方案。
若要恢复部署前已有文件，在检查备份内容后使用 `tar -tzf 备份文件` 和 `tar -xzf 备份文件 -C /`，再按原先方式启用服务。
备份只包含原来存在且将被覆盖的文件；新增加的文件需按卸载清单移除。备份不记录旧服务自启状态。

## 接口依据

- [OpenWrt procd 文档](https://openwrt.org/docs/guide-developer/procd-init-scripts)：实例、respawn、term_timeout、配置重载。
- [OpenWrt 25.12 procd.sh](https://github.com/openwrt/openwrt/blob/openwrt-25.12/package/system/procd/files/procd.sh)：服务参数及 reload trigger。
- [rpcd plugin.c](https://github.com/openwrt/rpcd/blob/master/plugin.c)：可执行插件的 list / call 协议。
- [LuCI 25.12 form.js](https://github.com/openwrt/luci/blob/openwrt-25.12/modules/luci-base/htdocs/luci-static/resources/form.js)：Map、NamedSection、依赖与 retain、验证。
- [LuCI 官方示例](https://github.com/openwrt/luci/tree/openwrt-25.12/applications/luci-app-example)：JavaScript view、menu.d 和 ACL 组织方式。
- [OpenWrt 25.12 发布说明](https://openwrt.org/releases/25.12/notes-25.12.0)：APK 迁移。

此架构使用 rpcd 自带可执行插件机制，因此无需自行假设或实现 ucode ubus 服务 API。前端仅能读自定义状态和读写本插件的 UCI 配置，未开放任意命令执行或任意文件写入权限。
