"""Generate a deterministic Xcode project without requiring XcodeGen or CocoaPods.

Only project/assets generation runs on Windows. Compilation requires macOS/Xcode.
"""
from pathlib import Path
import hashlib
import json
import plistlib
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / 'ios'
APP = IOS / 'Lanpixo'
PROJECT = IOS / 'Lanpixo.xcodeproj'

def uid(name):
    return hashlib.sha1(name.encode()).hexdigest()[:24].upper()

def quote(value):
    return json.dumps(str(value), ensure_ascii=False)

def generate():
    assets = APP / 'Assets.xcassets'
    assets.mkdir(exist_ok=True)
    (assets / 'Contents.json').write_text(json.dumps({'info': {'author': 'xcode', 'version': 1}}), encoding='utf-8')
    # Render the established Lanpixo vector geometry at native 1024px, without upscaling a store PNG.
    size = 1024
    icon = Image.new('RGB', (size, size), '#111C2B')
    draw = ImageDraw.Draw(icon)
    def point(x, y): return (round(x / 30 * size + 102), round(y / 30 * size + 102))
    draw.line([point(6, 7), point(6, 19), point(17, 19)], fill='#FF674E', width=60, joint='curve')
    for x, y in [(6, 7), (6, 19), (17, 19)]:
        px, py = point(x, y); draw.ellipse((px-30, py-30, px+30, py+30), fill='#FF674E')
    for x, y in [(6, 5), (19, 19)]:
        px, py = point(x, y); r = 68
        draw.ellipse((px-r, py-r, px+r, py+r), outline='#FF674E', width=60)
    appicon = assets / 'AppIcon.appiconset'; appicon.mkdir(exist_ok=True)
    icon.save(appicon / 'AppIcon.png')
    (appicon / 'Contents.json').write_text(json.dumps({'images': [{'filename': 'AppIcon.png', 'idiom': 'universal', 'platform': 'ios', 'size': '1024x1024'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2), encoding='utf-8')
    brand = assets / 'Brand.imageset'; brand.mkdir(exist_ok=True)
    icon.resize((128, 128), Image.Resampling.LANCZOS).save(brand / 'Brand.png')
    (brand / 'Contents.json').write_text(json.dumps({'images': [{'filename': 'Brand.png', 'idiom': 'universal'}], 'info': {'author': 'xcode', 'version': 1}}, indent=2), encoding='utf-8')

    types = ['_http._tcp.', '_https._tcp.', '_ssh._tcp.', '_smb._tcp.', '_ipp._tcp.', '_ipps._tcp.', '_airplay._tcp.', '_raop._tcp.', '_googlecast._tcp.', '_companion-link._tcp.', '_hap._tcp.', '_workstation._tcp.']
    info = {
        'CFBundleDevelopmentRegion': 'en', 'CFBundleDisplayName': 'Lanpixo',
        'CFBundleExecutable': '$(EXECUTABLE_NAME)', 'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)',
        'CFBundleInfoDictionaryVersion': '6.0', 'CFBundleName': '$(PRODUCT_NAME)', 'CFBundlePackageType': 'APPL',
        'CFBundleShortVersionString': '$(MARKETING_VERSION)', 'CFBundleVersion': '$(CURRENT_PROJECT_VERSION)',
        'LSRequiresIPhoneOS': True, 'UILaunchScreen': {},
        'UISupportedInterfaceOrientations': ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'],
        'UISupportedInterfaceOrientations~ipad': ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationPortraitUpsideDown', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'],
        'NSLocalNetworkUsageDescription': 'Lanpixo discovers responding devices and services on your Wi-Fi network when you start a scan.',
        'NSBonjourServices': types,
        # Local TCP discovery is not an arbitrary internet HTTP transport exception.
        'NSAppTransportSecurity': {'NSAllowsLocalNetworking': True},
        'UIFileSharingEnabled': False,
        'ITSAppUsesNonExemptEncryption': False,
        'GADApplicationIdentifier': 'ca-app-pub-4333526146021563~5868530963',
        'GADDelayAppMeasurementInit': True,
        'LanpixoAdEnvironment': '$(LANPIXO_AD_ENVIRONMENT)',
        'SKAdNetworkItems': [{'SKAdNetworkIdentifier': 'cstr6suwn9.skadnetwork'}],
    }
    (APP / 'Info.plist').write_bytes(plistlib.dumps(info, sort_keys=False))
    privacy = {
        'NSPrivacyTracking': False, 'NSPrivacyTrackingDomains': [],
        # Speed-test metadata plus restricted, non-personalized Google ads.
        # SDK manifests remain embedded separately and must not be rewritten.
        'NSPrivacyCollectedDataTypes': [
            {'NSPrivacyCollectedDataType': name,
             'NSPrivacyCollectedDataTypeLinked': name not in ['NSPrivacyCollectedDataTypeCrashData', 'NSPrivacyCollectedDataTypeOtherDiagnosticData'],
             'NSPrivacyCollectedDataTypeTracking': False,
             'NSPrivacyCollectedDataTypePurposes':
                 ['NSPrivacyCollectedDataTypePurposeAppFunctionality', 'NSPrivacyCollectedDataTypePurposeAnalytics']
                 if name in ['NSPrivacyCollectedDataTypeOtherDataTypes', 'NSPrivacyCollectedDataTypeOtherUsageData']
                 else ['NSPrivacyCollectedDataTypePurposeAnalytics'] if name == 'NSPrivacyCollectedDataTypeCrashData'
                 else ['NSPrivacyCollectedDataTypePurposeAppFunctionality', 'NSPrivacyCollectedDataTypePurposeAnalytics', 'NSPrivacyCollectedDataTypePurposeThirdPartyAdvertising']}
            for name in ['NSPrivacyCollectedDataTypeOtherDataTypes', 'NSPrivacyCollectedDataTypeOtherUsageData',
                         'NSPrivacyCollectedDataTypeCoarseLocation', 'NSPrivacyCollectedDataTypeDeviceID',
                         'NSPrivacyCollectedDataTypeProductInteraction', 'NSPrivacyCollectedDataTypeAdvertisingData',
                         'NSPrivacyCollectedDataTypeCrashData', 'NSPrivacyCollectedDataTypePerformanceData',
                         'NSPrivacyCollectedDataTypeOtherDiagnosticData']
        ],
        'NSPrivacyAccessedAPITypes': [{'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults', 'NSPrivacyAccessedAPITypeReasons': ['CA92.1']}],
    }
    (APP / 'PrivacyInfo.xcprivacy').write_bytes(plistlib.dumps(privacy, sort_keys=False))
    for language, description in {
        'en': 'Lanpixo discovers responding devices and services on your Wi-Fi network when you start a scan.',
        'tr': 'Lanpixo, sen bir tarama başlattığında Wi-Fi ağında yanıt veren cihazları ve servisleri keşfeder.'
    }.items():
        folder = APP / f'{language}.lproj'; folder.mkdir(exist_ok=True)
        (folder / 'InfoPlist.strings').write_text('"NSLocalNetworkUsageDescription" = ' + quote(description) + ';\n', encoding='utf-8')

    sources = sorted(str(p.relative_to(APP)).replace('\\', '/') for p in APP.rglob('*.swift'))
    resources = ['Assets.xcassets', 'PrivacyInfo.xcprivacy']
    objects = []
    def obj(name, value): objects.append(f'\t\t{uid(name)} = {{ {value} }};')
    for path in sources + resources:
        kind = 'sourcecode.swift' if path.endswith('.swift') else 'folder.assetcatalog' if path.endswith('.xcassets') else 'text.xml'
        obj('ref:' + path, f'isa = PBXFileReference; lastKnownFileType = {kind}; path = {quote(path)}; sourceTree = "<group>";')
        obj('build:' + path, f'isa = PBXBuildFile; fileRef = {uid("ref:" + path)};')
    for language in ['en', 'tr']:
        obj('lang:' + language, f'isa = PBXFileReference; lastKnownFileType = text.plist.strings; name = {language}; path = {language}.lproj/InfoPlist.strings; sourceTree = "<group>";')
    obj('localization', f'isa = PBXVariantGroup; children = ({uid("lang:en")}, {uid("lang:tr")},); name = InfoPlist.strings; sourceTree = "<group>";')
    obj('build:localization', f'isa = PBXBuildFile; fileRef = {uid("localization")};')
    obj('app', 'isa = PBXFileReference; explicitFileType = wrapper.application; path = Lanpixo.app; sourceTree = BUILT_PRODUCTS_DIR;')
    children = ', '.join(uid('ref:' + p) for p in sources + resources)
    obj('sourceGroup', f'isa = PBXGroup; children = ({children}, {uid("localization")},); path = Lanpixo; sourceTree = "<group>";')
    obj('products', f'isa = PBXGroup; children = ({uid("app")},); name = Products; sourceTree = "<group>";')
    obj('rootGroup', f'isa = PBXGroup; children = ({uid("sourceGroup")}, {uid("products")},); sourceTree = "<group>";')
    for phase, paths in [('sources', sources), ('resources', resources)]:
        builds = [uid('build:' + p) for p in paths]
        if phase == 'resources': builds.append(uid('build:localization'))
        obj(phase, f'isa = PBX{phase.title()}BuildPhase; buildActionMask = 2147483647; files = ({", ".join(builds)},); runOnlyForDeploymentPostprocessing = 0;')
    obj('ads:package', 'isa = XCRemoteSwiftPackageReference; repositoryURL = "https://github.com/googleads/swift-package-manager-google-mobile-ads.git"; requirement = { kind = exactVersion; version = 13.13.0; };')
    obj('ads:product', f'isa = XCSwiftPackageProductDependency; package = {uid("ads:package")}; productName = GoogleMobileAds;')
    obj('ads:build', f'isa = PBXBuildFile; productRef = {uid("ads:product")};')
    obj('frameworks', f'isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = ({uid("ads:build")},); runOnlyForDeploymentPostprocessing = 0;')
    for scope in ['project', 'target']:
        for config in ['Debug', 'Release']:
            settings = {
                'IPHONEOS_DEPLOYMENT_TARGET': '17.0', 'SWIFT_VERSION': '5.0', 'SDKROOT': 'iphoneos',
                'CLANG_ENABLE_MODULES': 'YES', 'SWIFT_STRICT_CONCURRENCY': 'minimal',
            }
            if config == 'Debug': settings.update({'SWIFT_OPTIMIZATION_LEVEL': '-Onone', 'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'DEBUG'})
            else: settings.update({'SWIFT_OPTIMIZATION_LEVEL': '-O', 'DEBUG_INFORMATION_FORMAT': 'dwarf-with-dsym'})
            if scope == 'target':
                settings.update({'PRODUCT_BUNDLE_IDENTIFIER': 'com.netora.scanner', 'PRODUCT_NAME': '$(TARGET_NAME)',
                    'INFOPLIST_FILE': 'Lanpixo/Info.plist', 'GENERATE_INFOPLIST_FILE': 'NO', 'MARKETING_VERSION': '0.2.0',
                    'CURRENT_PROJECT_VERSION': '1', 'TARGETED_DEVICE_FAMILY': '1,2', 'CODE_SIGN_STYLE': 'Automatic',
                    'LANPIXO_AD_ENVIRONMENT': 'test',
                    'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon', 'ENABLE_PREVIEWS': 'YES', 'DEVELOPMENT_TEAM': 'M64GVYHN8L',
                    'SUPPORTS_MACCATALYST': 'NO', 'SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD': 'NO'})
            values = ' '.join(f'{k} = {quote(v)};' for k, v in settings.items())
            obj(f'{scope}:{config}', f'isa = XCBuildConfiguration; buildSettings = {{ {values} }}; name = {config};')
        obj(scope + ':configs', f'isa = XCConfigurationList; buildConfigurations = ({uid(scope + ":Debug")}, {uid(scope + ":Release")},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;')
    obj('target', f'isa = PBXNativeTarget; buildConfigurationList = {uid("target:configs")}; buildPhases = ({uid("sources")}, {uid("frameworks")}, {uid("resources")},); buildRules = (); dependencies = (); packageProductDependencies = ({uid("ads:product")},); name = Lanpixo; productName = Lanpixo; productReference = {uid("app")}; productType = "com.apple.product-type.application";')
    obj('project', f'isa = PBXProject; attributes = {{ BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2600; }}; buildConfigurationList = {uid("project:configs")}; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, tr, Base,); mainGroup = {uid("rootGroup")}; productRefGroup = {uid("products")}; projectDirPath = ""; projectRoot = ""; packageReferences = ({uid("ads:package")},); targets = ({uid("target")},);')
    PROJECT.mkdir(exist_ok=True)
    (PROJECT / 'project.pbxproj').write_text('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {};\n\tobjectVersion = 56;\n\tobjects = {\n' + '\n'.join(objects) + '\n\t};\n\trootObject = ' + uid('project') + ';\n}\n', encoding='utf-8')
    scheme = PROJECT / 'xcshareddata/xcschemes'; scheme.mkdir(parents=True, exist_ok=True)
    reference = f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{uid("target")}" BuildableName="Lanpixo.app" BlueprintName="Lanpixo" ReferencedContainer="container:Lanpixo.xcodeproj"/>'
    (scheme / 'Lanpixo.xcscheme').write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2600" version="1.3">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{reference}</BuildActionEntry></BuildActionEntries></BuildAction>
  <TestAction buildConfiguration="Debug" shouldUseLaunchSchemeArgsEnv="YES"/>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="NO"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{reference}</BuildableProductRunnable></ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>
''', encoding='utf-8')
    print(f'Generated {PROJECT}: {len(sources)} Swift files; bundle ID com.netora.scanner')

if __name__ == '__main__': generate()
