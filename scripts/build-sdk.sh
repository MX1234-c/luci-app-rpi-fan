#!/bin/bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "$0")/.." && pwd)
build_dir="$source_dir/work/sdk"
sdk_name=openwrt-sdk-25.12.6-bcm27xx-bcm2710_gcc-14.3.0_musl.Linux-x86_64.tar.zst
sdk_sha=9b10b56e766edc47d1cca5ebd44918777516b67a0878dbc43950ecc445217462
sdk_url="https://downloads.openwrt.org/releases/25.12.6/targets/bcm27xx/bcm2710/$sdk_name"
mkdir -p "$source_dir/work" "$source_dir/release"
if [ -e "$build_dir" ]; then
 echo 'work/sdk already exists; use a clean checkout for a reproducible build.' >&2
 exit 1
fi
cd "$source_dir/work"
wget --https-only -O "$sdk_name" "$sdk_url"
echo "$sdk_sha  $sdk_name" | sha256sum -c -
mkdir "$build_dir"
tar --zstd -xf "$sdk_name" -C "$build_dir" --strip-components=1
cd "$build_dir"
./scripts/feeds update -a
./scripts/feeds install luci-base
mkdir -p package/luci-app-rpi-fan
cp "$source_dir/Makefile" package/luci-app-rpi-fan/
cp -R "$source_dir/root" "$source_dir/htdocs" package/luci-app-rpi-fan/
echo 'CONFIG_PACKAGE_luci-app-rpi-fan=m' >> .config
make defconfig
make -j2 package/luci-app-rpi-fan/compile V=s
mapfile -t packages < <(find bin -type f -name 'luci-app-rpi-fan-*.apk')
if [ "${#packages[@]}" -ne 1 ]; then
 echo "Expected exactly one APK; found ${#packages[@]}" >&2
 exit 1
fi
cp "${packages[0]}" "$source_dir/release/"
cd "$source_dir/release"
sha256sum ./*.apk > SHA256SUMS
cp "$source_dir/LICENSE" .
cp "$source_dir/docs/INSTALL.md" INSTALL.md
