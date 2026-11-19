#!/bin/bash
# Run only inside the ephemeral, manually dispatched macOS job. Never enable shell tracing.
set -euo pipefail
for name in P12_BASE64 P12_PASSWORD PROFILE_BASE64; do
  if [ -z "${!name:-}" ]; then echo "Missing required signing secret: $name"; exit 1; fi
done
if [ "$SHOULD_UPLOAD" = true ]; then
  for name in ASC_KEY_ID ASC_ISSUER_ID ASC_PRIVATE_KEY; do
    if [ -z "${!name:-}" ]; then echo "Missing App Store Connect secret: $name"; exit 1; fi
  done
fi
umask 077
printf '%s' "$P12_BASE64" | base64 --decode > "$RUNNER_TEMP/lanpixo-signing.p12"
printf '%s' "$PROFILE_BASE64" | base64 --decode > "$RUNNER_TEMP/lanpixo-profile.mobileprovision"
security cms -D -i "$RUNNER_TEMP/lanpixo-profile.mobileprovision" > "$RUNNER_TEMP/lanpixo-profile.plist"
python3 - <<'PY'
import os, plistlib, pathlib, shutil, re, datetime
root=pathlib.Path(os.environ['RUNNER_TEMP'])
profile=plistlib.loads((root/'lanpixo-profile.plist').read_bytes())
team=os.environ['APPLE_TEAM_ID']
assert profile['TeamIdentifier'] == [team], 'Wrong signing team'
assert profile['Entitlements']['application-identifier'] == team+'.com.netora.scanner', 'Wrong bundle identifier'
assert not profile['Entitlements'].get('get-task-allow', True), 'Development profile is not accepted'
assert 'ProvisionedDevices' not in profile and not profile.get('ProvisionsAllDevices', False), 'App Store distribution profile required'
assert profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None), 'Expired profile'
uuid=profile['UUID']; name=profile['Name']
assert re.fullmatch(r'[A-Fa-f0-9-]+', uuid)
assert '\n' not in name and '\r' not in name
directory=pathlib.Path.home()/'Library/MobileDevice/Provisioning Profiles'
directory.mkdir(parents=True,exist_ok=True)
shutil.copyfile(root/'lanpixo-profile.mobileprovision',directory/(uuid+'.mobileprovision'))
(root/'lanpixo-installed-profile.txt').write_text(str(directory/(uuid+'.mobileprovision')))
options={'method':'app-store-connect','destination':'export','teamID':team,'signingStyle':'manual','provisioningProfiles':{'com.netora.scanner':name},'uploadSymbols':True,'manageAppVersionAndBuildNumber':False}
(root/'LanpixoExportOptions.plist').write_bytes(plistlib.dumps(options))
with open(os.environ['GITHUB_ENV'],'a') as f:
 f.write('LANPIXO_PROFILE_NAME='+name+'\n')
 if os.environ.get('ASC_KEY_ID'):
  key=os.environ['ASC_KEY_ID']; issuer=os.environ['ASC_ISSUER_ID']
  assert re.fullmatch(r'[A-Z0-9]+',key) and re.fullmatch(r'[A-Fa-f0-9-]+',issuer)
  f.write('LANPIXO_ASC_KEY_ID='+key+'\nLANPIXO_ASC_ISSUER_ID='+issuer+'\n')
  keys=pathlib.Path.home()/'.appstoreconnect/private_keys';keys.mkdir(parents=True,exist_ok=True)
  (keys/('AuthKey_'+key+'.p8')).write_text(os.environ['ASC_PRIVATE_KEY'])
  (root/'lanpixo-installed-key.txt').write_text(str(keys/('AuthKey_'+key+'.p8')))
PY
KEYCHAIN_PASSWORD=$(openssl rand -base64 32)
KEYCHAIN_PATH="$RUNNER_TEMP/lanpixo-signing.keychain-db"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 1800 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$RUNNER_TEMP/lanpixo-signing.p12" -P "$P12_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple:,codesign: -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH" >/dev/null
security list-keychains -d user -s "$KEYCHAIN_PATH" "$HOME/Library/Keychains/login.keychain-db"
