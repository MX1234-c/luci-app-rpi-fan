#!/bin/sh
# Read-only smoke test; does not change fan configuration or service state.
set -eu
fail() { echo "FAIL: $*"; exit 1; }
[ -d /sys/class/pwm/pwmchip0/pwm0 ] || fail 'pwm0 not exported'
[ "$(cat /sys/class/pwm/pwmchip0/pwm0/period)" = 1000000 ] || fail 'wrong period'
[ "$(cat /sys/class/pwm/pwmchip0/pwm0/polarity)" = normal ] || fail 'wrong polarity'
[ "$(cat /sys/class/pwm/pwmchip0/pwm0/enable)" = 1 ] || fail 'PWM disabled'
/etc/init.d/rpi-fan enabled || fail 'boot service disabled'
ubus -v list rpi-fan
data=$(ubus call rpi-fan status)
printf '%s\n' "$data"
[ "$(jsonfilter -s "$data" -e '@.running')" = true ] || fail 'service not updating'
[ "$(jsonfilter -s "$data" -e '@.pwm_ok')" = true ] || fail 'PWM write failed'
reason=$(jsonfilter -s "$data" -e '@.reason')
case "$reason" in config_error|sensor_error|pwm_error) fail "$reason";; esac
echo 'PASS: live status, PWM setup and boot enablement; verify real fan movement separately'
