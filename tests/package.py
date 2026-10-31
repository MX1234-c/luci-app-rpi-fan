"""Package lifecycle contract; shell execution is separately exercised in SDK."""
from pathlib import Path
import os
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
makefile = (root / 'Makefile').read_text()
assert 'define Package/luci-app-rpi-fan/postinst' in makefile
postinst = makefile.split('define Package/luci-app-rpi-fan/postinst', 1)[1].split('endef', 1)[0]
assert 'IPKG_INSTROOT' in postinst, 'must not restart host services in offline images'
assert '/etc/init.d/rpcd restart' in postinst, 'must register executable ubus plugin'
assert '/etc/init.d/rpi-fan restart' in postinst, 'upgrades must replace the running controller'
assert '/etc/config/rpi-fan' in makefile.split('conffiles', 1)[1].split('endef', 1)[0]
package = makefile.split('define Package/luci-app-rpi-fan\n', 1)[1].split('endef', 1)[0]
assert 'PKGARCH:=all' in package, 'Package/Default overrides a global PKGARCH setting'
shell = os.environ.get('BASH_EXE') or shutil.which('bash')
if os.name == 'nt':
    shell = os.environ.get('BASH_EXE', 'D:/Program Files/Git/bin/bash.exe')
script = postinst.replace('$$', '$')
script = script.replace('/etc/init.d/rpcd restart', 'echo RPC_RESTART')
script = script.replace('/etc/init.d/rpi-fan restart', 'echo FAN_RESTART')
for offline, expected in [('/offline-image', ''), ('', 'RPC_RESTART\nFAN_RESTART\n')]:
    result = subprocess.run([shell, '-c', script], env=dict(os.environ, IPKG_INSTROOT=offline),
                            check=True, capture_output=True, text=True)
    assert result.stdout == expected, (offline, result.stdout)
print('PASS: package config preservation, architecture and guarded RPC registration')
