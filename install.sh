#!/bin/sh
# Direct deployment on OpenWrt; run from the extracted source directory.
set -eu
cd "$(dirname "$0")"
[ "$(id -u)" = 0 ] || { echo 'Run as root'; exit 1; }
[ -r /etc/openwrt_release ] || { echo 'OpenWrt required'; exit 1; }
for cmd in uci ubus jsonfilter logger tar; do
 command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd"; exit 1; }
done
[ -r /lib/functions.sh ] && [ -x /etc/init.d/rpcd ] && [ -d /www/luci-static/resources/view ] || {
 echo 'Install luci-base and rpcd first'; exit 1;
}
[ -d /sys/class/pwm/pwmchip0 ] || { echo 'pwmchip0 missing: restore the already verified PWM overlay first'; exit 1; }
if command -v apk >/dev/null && apk info -e luci-app-rpi-fan >/dev/null 2>&1; then
 echo 'Package-managed installation exists; upgrade/remove it with apk instead.'; exit 1
fi
# Back up only existing files we will replace. Preserve UCI configuration.
backup=/root/rpi-fan-backup-$(date +%Y%m%d-%H%M%S)-$$.tar.gz
set --
for f in etc/config/rpi-fan etc/init.d/rpi-fan usr/sbin/rpi-fand usr/lib/rpi-fan/control.sh usr/libexec/rpcd/rpi-fan usr/share/luci/menu.d/luci-app-rpi-fan.json usr/share/rpcd/acl.d/luci-app-rpi-fan.json www/luci-static/resources/view/rpi-fan.js; do
 [ ! -e "/$f" ] || set -- "$@" "$f"
done
if [ "$#" -gt 0 ]; then tar -czf "$backup" -C / "$@"; echo "Backup: $backup"; fi
[ ! -x /etc/init.d/rpi-fan ] || /etc/init.d/rpi-fan stop
mkdir -p /etc/config /etc/init.d /usr/sbin /usr/lib/rpi-fan /usr/libexec/rpcd /usr/share/luci/menu.d /usr/share/rpcd/acl.d
if [ ! -e /etc/config/rpi-fan ]; then cp root/etc/config/rpi-fan /etc/config/rpi-fan; fi
cp root/etc/init.d/rpi-fan /etc/init.d/rpi-fan
cp root/usr/sbin/rpi-fand /usr/sbin/rpi-fand
cp root/usr/lib/rpi-fan/control.sh /usr/lib/rpi-fan/control.sh
cp root/usr/libexec/rpcd/rpi-fan /usr/libexec/rpcd/rpi-fan
cp root/usr/share/luci/menu.d/luci-app-rpi-fan.json /usr/share/luci/menu.d/
cp root/usr/share/rpcd/acl.d/luci-app-rpi-fan.json /usr/share/rpcd/acl.d/
cp htdocs/luci-static/resources/view/rpi-fan.js /www/luci-static/resources/view/
chmod 755 /etc/init.d/rpi-fan /usr/sbin/rpi-fand /usr/libexec/rpcd/rpi-fan
chmod 644 /usr/lib/rpi-fan/control.sh /etc/config/rpi-fan /usr/share/luci/menu.d/luci-app-rpi-fan.json /usr/share/rpcd/acl.d/luci-app-rpi-fan.json /www/luci-static/resources/view/rpi-fan.js
/etc/init.d/rpi-fan enable
rm -f /tmp/luci-indexcache.*
/etc/init.d/rpcd restart
/etc/init.d/rpi-fan restart
echo 'Installed. Re-login to LuCI, then open Services / 树莓派风扇.'
echo 'Check: ubus call rpi-fan status; logread -e rpi-fan'
