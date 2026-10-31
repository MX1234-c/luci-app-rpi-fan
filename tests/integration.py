"""Host fixture tests. Never access the real host /sys, UCI or services."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

BASE = Path(__file__).resolve().parents[1]
BASH = os.environ.get('BASH_EXE') or shutil.which('bash')
if os.name == 'nt':
    BASH = os.environ.get('BASH_EXE', 'D:/Program Files/Git/bin/bash.exe')

def run(*args):
    return subprocess.run([BASH, *map(str, args)], check=True, text=True,
                          capture_output=True, cwd=BASE).stdout

for name in ['control.sh', 'pwm.sh']:
    print(run(BASE / 'tests' / name).strip())

for path in BASE.rglob('*'):
    if path.is_file() and (path.suffix == '.sh' or path.name in ['rpi-fand', 'rpi-fan'] and 'config' not in path.parts):
        run('-n', path)
    if path.suffix == '.json':
        json.loads(path.read_text(encoding='utf-8'))
print('PASS: shell syntax and JSON manifests')

defaults = dict(enabled='1', mode='auto', manual='50', minimum='40',
                stop='45', start='50', full='70', critical='80')
cases = [({}, '60000', 70, 'normal'), ({'enabled': '0'}, '60000', 0, 'off'),
         ({'mode': 'manual', 'manual': '23'}, '60000', 23, 'normal'),
         ({'enabled': '0'}, '81000', 100, 'critical'),
         ({}, 'broken', 100, 'sensor_error'),
         ({'start': '20'}, '60000', 100, 'config_error')]

for case_number, (changes, temperature, target, reason) in enumerate(cases):
    with tempfile.TemporaryDirectory(prefix='rpi-fan-test-') as d:
        fixture = Path(d)
        # Shell-friendly paths on Windows Git Bash as well as POSIX hosts.
        def q(p):
            return "'" + str(p).replace('\\', '/').replace("'", "'\\''") + "'"
        pwm = fixture / 'pwm0'
        pwm.mkdir()
        for file, value in dict(period=1000000, duty_cycle=0, enable=1, polarity='normal').items():
            (pwm / file).write_text(str(value) + '\n')
        (fixture / 'temp').write_text(temperature)
        conf = defaults | changes
        stubs = 'config_load() { return 0; }\nconfig_get() {\ncase "$1" in\n'
        stubs += ''.join(f'{k}) {k}={q(v)};;\n' for k, v in conf.items())
        stubs += 'esac\n}\n'
        (fixture / 'functions').write_text(stubs, newline='\n')
        daemon = (BASE / 'root/usr/sbin/rpi-fand').read_text()
        daemon = daemon.replace('. /lib/functions.sh', '. ' + q(fixture / 'functions'))
        daemon = daemon.replace('. /usr/lib/rpi-fan/control.sh', '. ' + q(BASE / 'root/usr/lib/rpi-fan/control.sh'))
        daemon = daemon.replace('chip=/sys/class/pwm/pwmchip0', 'chip=' + q(fixture))
        daemon = daemon.replace('status=/var/run/rpi-fan.json', 'status=' + q(fixture / 'status.json'))
        daemon = daemon.replace('/sys/class/thermal/thermal_zone0/temp', q(fixture / 'temp'))
        # Execute one full loop, then normal EXIT cleanup. Keep a status snapshot.
        terminate = 'kill -TERM $$' if case_number % 2 else 'exit 0'
        prelude = f'''logger() {{ :; }}
sleep() {{
 if [ "$1" = 2 ]; then cp "$status" {q(fixture / 'snapshot.json')}; {terminate}; fi
}}
'''
        script = fixture / 'daemon.sh'
        script.write_text(prelude + daemon, newline='\n')
        run(script)
        status = json.loads((fixture / 'snapshot.json').read_text())
        assert status['target'] == target and status['reason'] == reason, status
        assert status['actual'] == target and status['pwm_ok'] is True, status
        assert (pwm / 'duty_cycle').read_text().strip() == '1000000', 'stop must cool'
        assert not (fixture / 'status.json').exists(), 'stop must clear status'
print('PASS: six daemon scenarios, status JSON and full-speed EXIT/TERM shutdown')

plugin = BASE / 'root/usr/libexec/rpcd/rpi-fan'
assert json.loads(run(plugin, 'list')) == {'status': {}}
print('PASS: rpcd executable signature')

with tempfile.TemporaryDirectory(prefix='rpi-fan-rpc-') as d:
    fixture = Path(d)
    state_file = fixture / 'status.json'
    quoted = "'" + str(state_file).replace('\\', '/') + "'"
    now = int(run('-c', 'read -r up rest < /proc/uptime; echo "${up%%.*}"').strip())
    for stamp, expected in [(now, True), (now + 100, False), ('bad', False)]:
        state_file.write_text(json.dumps(dict(running=True, updated=stamp)))
        body = f"jsonfilter() {{ printf '%s\\n' '{stamp}'; }}\n"
        body += plugin.read_text().replace('/var/run/rpi-fan.json', quoted)
        script = fixture / 'rpc.sh'
        script.write_text(body, newline='\n')
        assert json.loads(run(script, 'call', 'status'))['running'] is expected
print('PASS: rpcd fresh, future and malformed timestamp handling (jsonfilter fixture)')
