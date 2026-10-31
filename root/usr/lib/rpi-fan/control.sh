#!/bin/sh
# Shared pure controller and checked PWM I/O. All paths fixed by daemon.
uint() {
 case "$1" in ''|*[!0-9]*|0[0-9]*) return 1;; esac
 [ "${#1}" -le 7 ] && [ "$1" -ge "$2" ] && [ "$1" -le "$3" ]
}
valid_config() {
 uint "$enabled" 0 1 && { [ "$mode" = auto ] || [ "$mode" = manual ]; } &&
 uint "$manual" 0 100 && uint "$minimum" 1 100 &&
 uint "$stop" 0 100 && uint "$start" 1 110 && uint "$full" 2 115 &&
 uint "$critical" 3 120 && [ "$stop" -lt "$start" ] &&
 [ "$start" -lt "$full" ] && [ "$full" -lt "$critical" ]
}
choose() {
 target=100 reason=normal
 if ! valid_config; then reason=config_error; return; fi
 if ! uint "$1" 0 150000; then reason=sensor_error; return; fi
 if [ "$1" -ge "$((critical * 1000))" ]; then reason=critical; return; fi
 if [ "$enabled" = 0 ]; then target=0; active=0; reason=off; return; fi
 if [ "$mode" = manual ]; then target=$manual; active=0; return; fi
 if [ "$1" -le "$((stop * 1000))" ]; then active=0
 elif [ "$1" -ge "$((start * 1000))" ]; then active=1; fi
 if [ "$active" = 0 ]; then target=0; return; fi
 if [ "$1" -ge "$((full * 1000))" ]; then target=100
 elif [ "$1" -le "$((start * 1000))" ]; then target=$minimum
 else target=$((minimum + (100 - minimum) * ($1 - start * 1000) / ((full - start) * 1000)))
 fi
}
put() { printf '%s\n' "$2" > "$pwm/$1"; }
read_pwm() { cat "$pwm/$1" 2>/dev/null; }
prepare_pwm() {
 if [ ! -d "$pwm" ]; then
  printf '0\n' > "$chip/export" || return 1
  n=0
  while [ ! -d "$pwm" ] && [ "$n" -lt 3 ]; do sleep 1; n=$((n + 1)); done
 fi
 [ -d "$pwm" ] || return 1
 if [ "$(read_pwm period)" != 1000000 ] || [ "$(read_pwm polarity)" != normal ]; then
  put enable 0 && put duty_cycle 0 && put period 1000000 && put polarity normal || return 1
 fi
}
apply_pwm() {
 uint "$1" 0 100 || return 1
 prepare_pwm || return 1
 duty_ns=$(($1 * 10000))
 put duty_cycle "$duty_ns" && put enable 1 || return 1
 [ "$(read_pwm duty_cycle)" = "$duty_ns" ] && [ "$(read_pwm enable)" = 1 ]
}
