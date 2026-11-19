"""Launch the compiled app on real iOS Simulator runtimes in macOS CI.

Screenshots are launch/layout evidence, never physical-network test evidence.
"""
import json
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / 'ios/build/Build/Products/Debug-iphonesimulator/Lanpixo.app'
OUT = ROOT / 'ios/qa/simulator'
OUT.mkdir(parents=True, exist_ok=True)

def run(*args):
    result = subprocess.run(args, check=True, capture_output=True, text=True, timeout=240)
    print(result.stdout.strip(), flush=True)
    return result.stdout

devices = json.loads(run('xcrun', 'simctl', 'list', 'devices', 'available', '-j'))['devices']
candidates = [device for runtime, entries in devices.items() if '.iOS-' in runtime for device in entries if device.get('isAvailable')]
phone = next(d for d in candidates if d['name'].startswith('iPhone'))
tablet = next(d for d in candidates if d['name'].startswith('iPad'))
manifest = []
for device, language, theme in [(phone, 'en', 'light'), (phone, 'tr', 'dark'), (tablet, 'en', 'light')]:
    udid = device['udid']
    if device['state'] != 'Booted':
        # Device state is updated after the first boot for the repeated phone run.
        run('xcrun', 'simctl', 'boot', udid)
        run('xcrun', 'simctl', 'bootstatus', udid, '-b')
        device['state'] = 'Booted'
    run('xcrun', 'simctl', 'status_bar', udid, 'override', '--time', '9:41', '--batteryState', 'charged', '--batteryLevel', '100')
    run('xcrun', 'simctl', 'install', udid, str(APP))
    # Termination may fail on the first launch; this does not hide launch/install failures.
    subprocess.run(['xcrun', 'simctl', 'terminate', udid, 'com.netora.scanner'], capture_output=True)
    run('xcrun', 'simctl', 'launch', udid, 'com.netora.scanner', '-language', language, '-theme', theme)
    time.sleep(3)  # CI app layout/first-frame stabilization, not a discovery timeout.
    stem = ('ipad' if device is tablet else 'iphone') + '-' + language + '-' + theme
    path = OUT / (stem + '.png')
    run('xcrun', 'simctl', 'io', udid, 'screenshot', str(path))
    manifest.append({'device': device['name'], 'language': language, 'theme': theme, 'file': path.name, 'scope': 'simulator launch only'})
    if device is tablet: run('xcrun', 'simctl', 'shutdown', udid)
run('xcrun', 'simctl', 'shutdown', phone['udid'])
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
