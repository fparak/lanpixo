"""Delete only this job's specifically named temporary credentials."""
import os
from pathlib import Path
root=Path(os.environ['RUNNER_TEMP']).resolve()
home=Path.home().resolve()
for marker,allowed in [('lanpixo-installed-key.txt',home/'.appstoreconnect/private_keys'),('lanpixo-installed-profile.txt',home/'Library/MobileDevice/Provisioning Profiles')]:
 marker_path=root/marker
 if marker_path.exists():
  target=Path(marker_path.read_text()).resolve()
  if target.parent==allowed.resolve(): target.unlink(missing_ok=True)
  marker_path.unlink()
for name in ['lanpixo-signing.p12','lanpixo-profile.mobileprovision','lanpixo-profile.plist','LanpixoExportOptions.plist']:
 (root/name).unlink(missing_ok=True)
