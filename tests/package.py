"""Package lifecycle contract; shell execution is separately exercised in SDK."""
from pathlib import Path

root = Path(__file__).resolve().parents[1]
makefile = (root / 'Makefile').read_text()
assert 'define Package/luci-app-rpi-fan/postinst' in makefile
postinst = makefile.split('define Package/luci-app-rpi-fan/postinst', 1)[1].split('endef', 1)[0]
assert 'IPKG_INSTROOT' in postinst, 'must not restart host services in offline images'
assert '/etc/init.d/rpcd restart' in postinst, 'must register executable ubus plugin'
assert '/etc/config/rpi-fan' in makefile.split('conffiles', 1)[1].split('endef', 1)[0]
assert 'PKGARCH:=all' in makefile
print('PASS: package config preservation, architecture and guarded RPC registration')
