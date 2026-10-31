#!/bin/sh
set -eu
BASE=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
. "$BASE/root/usr/lib/rpi-fan/control.sh"
eq() { [ "$1" = "$2" ] || { echo "FAIL: $1 != $2 ($3)"; exit 1; }; }
enabled=1 mode=auto manual=50 stop=45 start=50 full=70 minimum=40 critical=80 active=0
choose 49000; eq "$target" 0 cold
choose 50000; eq "$target" 40 start
choose 60000; eq "$target" 70 ramp
choose 46000; eq "$target" 40 hysteresis
choose 45000; eq "$target" 0 stop
choose 70000; eq "$target" 100 full
enabled=0; choose 60000; eq "$target" 0 disabled
choose 80000; eq "$target" 100 critical
choose invalid; eq "$target" 100 sensor-failure
enabled=1 mode=manual manual=23; choose 60000; eq "$target" 23 manual
choose 80000; eq "$target" 100 manual-critical
for bad in '' -1 1.2 abc '1;id' 00000000001; do
  if uint "$bad" 0 100; then echo "FAIL accepted $bad"; exit 1; fi
done
uint 0 0 100; uint 100 0 100
enabled=1 mode=auto active=0
for temp in 0 44000 45000 49000 50000 51000 60000 69000 70000 79000 80000 150000; do
 choose "$temp"
 uint "$target" 0 100 || { echo 'FAIL: target out of range'; exit 1; }
done
for bad in '' 50.5 050 '$(id)' 10000000000000000; do
 manual=$bad; choose 60000; eq "$target" 100 invalid-config
 eq "$reason" config_error invalid-config-reason
done
manual=50
start=70; choose 60000; eq "$reason" config_error equal-thresholds
echo 'PASS: control boundaries, ramp, hysteresis, off, manual, fail-safe, validation'
