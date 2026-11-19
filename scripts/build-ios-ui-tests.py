"""Add an unsigned UI-test target to a CI-only copy of the project.

Does not change app sources, production scheme or the uploaded binary.
"""
from pathlib import Path
import hashlib

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / 'ios/Lanpixo.xcodeproj'
def uid(name): return hashlib.sha1(name.encode()).hexdigest()[:24].upper()

text = (PROJECT / 'project.pbxproj').read_text(encoding='utf-8')
objects = []
def obj(name, content): objects.append(f'\t\t{uid(name)} = {{ {content} }};')
obj('ui:ref', 'isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = StoreUITests.swift; sourceTree = "<group>";')
obj('ui:build', f'isa = PBXBuildFile; fileRef = {uid("ui:ref")};')
obj('ui:group', f'isa = PBXGroup; children = ({uid("ui:ref")},); path = LanpixoUITests; sourceTree = "<group>";')
obj('ui:product', 'isa = PBXFileReference; explicitFileType = wrapper.cfbundle; path = LanpixoUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR;')
obj('ui:sources', f'isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = ({uid("ui:build")},); runOnlyForDeploymentPostprocessing = 0;')
obj('ui:frameworks', 'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0;')
obj('ui:proxy', f'isa = PBXContainerItemProxy; containerPortal = {uid("project")}; proxyType = 1; remoteGlobalIDString = {uid("target")}; remoteInfo = Lanpixo;')
obj('ui:dependency', f'isa = PBXTargetDependency; target = {uid("target")}; targetProxy = {uid("ui:proxy")};')
for config in ['Debug', 'Release']:
    obj('ui:' + config, f'''isa = XCBuildConfiguration; name = {config}; buildSettings = {{
        PRODUCT_NAME = "$(TARGET_NAME)"; PRODUCT_BUNDLE_IDENTIFIER = com.netora.scanner.uitests;
        GENERATE_INFOPLIST_FILE = YES; IPHONEOS_DEPLOYMENT_TARGET = 17.0;
        SDKROOT = iphoneos; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = "1,2";
        TEST_TARGET_NAME = Lanpixo; CODE_SIGNING_ALLOWED = NO;
        LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @loader_path/Frameworks";
    }};''')
obj('ui:configs', f'isa = XCConfigurationList; buildConfigurations = ({uid("ui:Debug")}, {uid("ui:Release")},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Debug;')
obj('ui:target', f'''isa = PBXNativeTarget; buildConfigurationList = {uid("ui:configs")};
    buildPhases = ({uid("ui:sources")}, {uid("ui:frameworks")},); buildRules = ();
    dependencies = ({uid("ui:dependency")},); name = LanpixoUITests;
    productName = LanpixoUITests; productReference = {uid("ui:product")};
    productType = "com.apple.product-type.bundle.ui-testing";''')
text = text.replace(f'children = ({uid("sourceGroup")},', f'children = ({uid("ui:group")}, {uid("sourceGroup")},')
text = text.replace(f'children = ({uid("app")},);', f'children = ({uid("app")}, {uid("ui:product")},);')
text = text.replace(f'targets = ({uid("target")},);', f'targets = ({uid("target")}, {uid("ui:target")},);')
text = text.replace('\n\t};\n\trootObject', '\n' + '\n'.join(objects) + '\n\t};\n\trootObject')
(PROJECT / 'project.pbxproj').write_text(text, encoding='utf-8')
app = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target")}" BuildableName="Lanpixo.app" BlueprintName="Lanpixo" ReferencedContainer="container:Lanpixo.xcodeproj"/>'
test = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("ui:target")}" BuildableName="LanpixoUITests.xctest" BlueprintName="LanpixoUITests" ReferencedContainer="container:Lanpixo.xcodeproj"/>'
(PROJECT / 'xcshareddata/xcschemes/LanpixoUI.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1640" version="1.3">
<BuildAction parallelizeBuildables="NO" buildImplicitDependencies="YES"><BuildActionEntries>
<BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="NO">{app}</BuildActionEntry>
<BuildActionEntry buildForTesting="YES" buildForRunning="NO" buildForProfiling="NO" buildForArchiving="NO" buildForAnalyzing="NO">{test}</BuildActionEntry>
</BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{test}</TestableReference></Testables></TestAction>
</Scheme>''', encoding='utf-8')
print('Generated CI-only LanpixoUI scheme')
