#!/bin/sh
set -eu
BASE=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$BASE/root/usr/lib/rpi-fan/control.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' 0
chip=$tmp
pwm=$tmp/pwm0
mkdir "$pwm"
printf '2000000\n' > "$pwm/period"
printf '1500000\n' > "$pwm/duty_cycle"
printf '1\n' > "$pwm/enable"
printf 'inversed\n' > "$pwm/polarity"
apply_pwm 50
[ "$(cat "$pwm/period")" = 1000000 ]
[ "$(cat "$pwm/duty_cycle")" = 500000 ]
[ "$(cat "$pwm/polarity")" = normal ]
apply_pwm 0
[ "$(cat "$pwm/duty_cycle")" = 0 ]
apply_pwm 100
[ "$(cat "$pwm/duty_cycle")" = 1000000 ]
# Production status parser must accept the full-scale nanosecond readback.
uint 1000000 0 1000000
# Rejected inputs must never reach hardware.
if apply_pwm '1;echo unsafe'; then exit 1; fi
# Reproduce the target trace boundary: printf emits the value but returns
# failure in the background environment. PWM writes must use the echo path
# already verified on the target, without discarding real write failures.
printf() { command printf "$@"; return 1; }
apply_pwm 0
[ "$(cat "$pwm/duty_cycle")" = 0 ]
apply_pwm 50
[ "$(cat "$pwm/duty_cycle")" = 500000 ]
apply_pwm 100
[ "$(cat "$pwm/duty_cycle")" = 1000000 ]
unset -f printf
# Real sysfs validates writes; emulate a write error at the helper boundary.
put() { return 1; }
if apply_pwm 50; then echo 'FAIL: ignored I/O error'; exit 1; fi
echo 'PASS: PWM normalize, zero, full, input rejection and I/O failure'
