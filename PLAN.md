# Implementation and design

Target: Raspberry Pi 3B+, OpenWrt 25.12.6, existing GPIO18 PWM pinmux.
Keep /sys/class/pwm/pwmchip0/pwm0 and 1000000 ns fixed. Do not alter overlays.

Use a POSIX shell controller (no additional interpreter), procd supervision,
UCI configuration and modern LuCI JavaScript forms. rpcd executable plugin
provides a read-only ubus status method; no browser shell execution permission.
UCI commit reload triggers restart the controller; it also checks config every
two seconds so the deployed files remain usable without custom ubus daemons.

Safety decisions: invalid config or temperature => full speed; critical
temperature overrides manual/off; clean stop => full speed, leave PWM exported.
PWM errors are reported and retried. Actual RPM cannot be measured with this wiring.

Tasks:
- [x] Test and implement pure control logic and sysfs writer.
- [x] Implement procd, UCI, rpcd, ACL and LuCI form/status integration.
- [x] Add deployment, SDK packaging and target acceptance instructions.
- [x] Run host tests, syntax checks and independent code review.
- [x] Final archive verification (recorded in TEST-REPORT.md).

Validation limits: no attached Pi, OpenWrt runtime, SDK or browser LuCI session.
Host tests cannot prove electrical behavior or target integration.

Review ledger: independent reviewer found hidden-option deletion and decimal
duty input mismatch; both now have regression tests and fixes. Initial PWM
readback test also caught a seven-digit full-scale validation limit, fixed.
No SDK build or device integration was claimed. No shared repository existed;
implementation is isolated in this new deliverable directory. Scope and
architecture come directly from the user's detailed implementation request.
