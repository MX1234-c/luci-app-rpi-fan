# Third-party APK release plan

Goal: publish an actual installable OpenWrt 25.12.6 APK for Raspberry Pi 3B+.
Keep the device-tested controller and GPIO18 PWM0 binding unchanged.
Use the official bcm2710 SDK, pinned archive and SHA256; GitHub Actions builds
and attaches the APK and checksums to a versioned release after host tests.

Arbitrary GPIO switching is deliberately omitted. It requires a matching boot
overlay/pinmux and reboot; a UCI value cannot implement that. Do not alter boot
files, networking or the user's running controller during packaging.

- [x] Add release workflow, package lifecycle and reproducible build instructions.
- [x] Add lifecycle regression test, then implement postinst RPC registration.
- [x] Update public installation/upgrade/migration/removal documentation.
- [x] Run tests and an independent packaging review.
- [x] Build APK with official SDK, verify successful job and published assets.
- [x] Install first APK r1 on the authorized Pi and verify config preservation/status.
- [ ] Optional final r1-to-r2 on-device upgrade (terminal re-login needed).

Risks checked: offline image-root scripts, preserved UCI, unmanaged deployment
migration, unsigned third-party APK disclosure, boot overlay prerequisites,
release version immutability, failing CI must not publish an APK.
