"""Static wiring and syntax validation; deliberately not an Xcode build claim."""
from pathlib import Path
import json
import plistlib
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / '.tools/ios-validation'))
from openstep_parser import OpenStepDecoder
from tree_sitter import Language, Parser
import tree_sitter_swift
from PIL import Image

app = ROOT / 'ios/Lanpixo'
parser = Parser(Language(tree_sitter_swift.language()))
errors = []
def walk(node, file):
    if node.type == 'ERROR' or node.is_missing:
        errors.append(f'{file}:{node.start_point}: {node.type}')
    for child in node.children: walk(child, file)
for path in (ROOT / 'ios').rglob('*.swift'):
    walk(parser.parse(path.read_bytes()).root_node, path.relative_to(ROOT))
assert not errors, errors
with (ROOT / 'ios/Lanpixo.xcodeproj/project.pbxproj').open(encoding='utf-8') as stream:
    project = OpenStepDecoder.ParseFromFile(stream)
objects = project['objects']
assert project['rootObject'] in objects
source_refs = {x['path'] for x in objects.values() if x.get('lastKnownFileType') == 'sourcecode.swift'}
assert source_refs == {str(x.relative_to(app)).replace('\\', '/') for x in app.rglob('*.swift')}
for value in objects.values():
    if value.get('isa') == 'PBXFileReference' and value.get('sourceTree') == '<group>':
        assert (app / value['path']).exists(), value['path']
target_settings = [x['buildSettings'] for x in objects.values() if x.get('isa') == 'XCBuildConfiguration' and 'PRODUCT_BUNDLE_IDENTIFIER' in x.get('buildSettings', {})]
assert len(target_settings) == 2
assert all(x['PRODUCT_BUNDLE_IDENTIFIER'] == 'com.netora.scanner' for x in target_settings)
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert info['NSLocalNetworkUsageDescription']
types = info['NSBonjourServices']
assert len(types) == len(set(types)) == 12
bonjour = (app / 'Networking/BonjourDiscovery.swift').read_text(encoding='utf-8')
assert all('"' + name + '"' in bonjour for name in types)
assert not info.get('NSAppTransportSecurity', {}).get('NSAllowsArbitraryLoads', False)
assert 'GADApplicationIdentifier' not in info
privacy = plistlib.loads((app / 'PrivacyInfo.xcprivacy').read_bytes())
assert not privacy['NSPrivacyTracking']
assert privacy['NSPrivacyAccessedAPITypes'][0]['NSPrivacyAccessedAPITypeReasons'] == ['CA92.1']
ET.parse(ROOT / 'ios/Lanpixo.xcodeproj/xcshareddata/xcschemes/Lanpixo.xcscheme')
for contents in (app / 'Assets.xcassets').rglob('Contents.json'): json.loads(contents.read_text())
with Image.open(app / 'Assets.xcassets/AppIcon.appiconset/AppIcon.png') as icon:
    assert icon.size == (1024, 1024) and icon.mode == 'RGB'
print(f'PASS: Swift syntax ({len(list((ROOT / "ios").rglob("*.swift")))} files), PBX references, bundle ID, Bonjour declarations, privacy plist, scheme and opaque 1024px icon.')
print('NOT RUN: Xcode compilation, XCTest, simulator UI, physical-device discovery, signing or upload.')
