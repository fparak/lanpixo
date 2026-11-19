# Lanpixo iOS — release preparation, 19 November 2026

## Subsequent owner testing and advertising work

The owner subsequently installed TestFlight 0.1.0 (3), reported that all devices matched the router list, and reported no functional problems. These are owner-reported results, not an independent device inspection. The remaining sections below preserve the original ad-free release-preparation history. Advertising version 0.2.0 has separate verification and release gates in `ADS-TEST-PLAN.md`; the old privacy statement and screenshots must not be assumed to cover it.

The requested iPad UI testing, privacy declarations and store screenshot preparation are complete. This is preparation for release, not an App Review submission or proof of discovery on a physical Wi-Fi network.

## Tested

| Device / environment | Evidence | Result |
| --- | --- | --- |
| iPad Pro 13-inch M4, iPadOS 18.5 Simulator | UI workflow 44443034762, source c9a40da | 3 UI cases passed, 0 failures |
| iPhone 16 Pro Max, iOS 18.5 Simulator | UI workflow 44443034762, source c9a40da | 3 UI cases passed, 0 failures |
| iPad stable landscape capture, same app code | UI workflow 44443034762, source c9a40da | 3 UI cases passed; actual landscape screenshot inspected without transition letterboxing |
| Simulator / iPhoneOS compile and core XCTest | Validation workflow 44443034723 | Passed |
| Signed Release archive, export, core XCTest and upload | Signed workflow 44443090821 | Passed, Apple accepted 0.1.0 (3) |

UI cases cover English/light Network, Speed, History, Settings and Privacy screens, reachable tab navigation, landscape Network/Speed, Turkish/dark screens, and accessibility text size. A visual check caught truncation of the scan action at the largest text size; fixed multiline vertical sizing and verified the complete label in a fresh screenshot. Store portrait images come from the preceding all-green workflow 44442330758 (identical application code, before the capture-harness-only adjustment). Tests do not start discovery or perform an internet speed test. Automated accessibility checks are not a complete VoiceOver audit; no App Store accessibility feature claims were made.

The initial UI run failed because a picker label was queried as a button instead of static text. A subsequent image revealed app-window capture during the rotation transition; the capture harness now waits for landscape window bounds and captures the full screen. These earlier attempts are retained as history, not counted as passing suites.

## Privacy and store assets

- Public TR/EN policy: https://epx-studio.com/privacy/lanpixo-ios.html . Verified HTTPS 200 and content match after deployment; Android policy was left intact.
- App Store Connect App Privacy published with explicit owner approval. Other Data / Other Usage Data, linked, functionality/analytics, no tracking; rationale in `PRIVACY-DISCLOSURE.md`.
- Embedded manifest matches the disclosed speed-test connection data; no advertising or purchase SDK. UserDefaults reason CA92.1. Apple's OS-only HTTPS use declared exempt in Info.plist.
- 12 genuine store cards: 3 screens × 2 languages × 2 device families. Native UI screenshots are unaltered inside vector caption layouts; no fabricated devices or speeds.
- Required canvases: iPhone medium Dynamic Island 1206×2622 and iPad 13-inch 2064×2752. All exported PNGs validated RGB without alpha, correct dimensions, and source image hashes.
- English and Turkish iPhone/iPad sets each show 3 of 10 App Screenshots after reloading App Store Connect. These are custom localized assets, not inherited English placeholders.
- Local editable SVG layouts and RGB PNGs are under `app-store/screenshots/`; provenance in `manifest.json`. The export bundle is `../releases/lanpixo-ios-store-assets.zip`. Generated images are stored in this workspace and App Store Connect; repository scripts can regenerate them from the recorded XCTest artifacts. Local upload proof: `qa/store-tr-iphone-uploaded.jpg`, `qa/store-tr-ipad-uploaded.jpg`.

## Current binary

- Bundle: com.netora.scanner; version 0.1.0, build 3.
- Apple upload accepted 19 November 2026 at 05:18:58 Türkiye time (02:18:58 UTC).
- Delivery UUID: 08ebc0a1-5025-47f5-910e-1dda662fbad0.
- Local IPA: `../releases/lanpixo-ios-0.1.0-3.ipa`.
- SHA256: d6f82fd20149ddd0f1d0d13d8427ecbba6ae0614e2d8c117dde122ab2eb709ff.
- Public workflow evidence: https://github.com/fparak/lanpixo/actions/runs/44443090821 . Public source: https://github.com/fparak/lanpixo .
- A non-blocking upload notice says iOS 27 SDK will be required from April 2027; this upload succeeded with the present SDK.

## Deferred to the owner / next stage

The owner explicitly deferred TestFlight installation and real-network tests. Do not report a successful physical iPhone scan, speed benchmark, router comparison, permission allow/deny flow, export of a real device list, or device-specific background/network-change behavior until those results are supplied. TestFlight processing/installation availability for build 3 has not been asserted here. No invitation was sent and no App Review submission was made. Final release readiness also depends on real-device results and any remaining App Store compliance/account requirements.


## TestFlight invitation update

On 19 November 2026 the owner requested the test invitation. Build 0.1.0 (3) finished processing and was added to the internal Lanpixo Device Tests group. The existing account holder was invited; App Store Connect showed Invited, one tester and one build, with the build Ready to Test. Automatic distribution is off. Installation and physical-network results are still unverified. Proof and compact status are in qa/testflight-invitation-sent-20261119.jpg and qa/testflight-invitation-status.json. Earlier no-invitation notes describe the preceding release-preparation stage.

## Live advertising update — 20 November 2026

The owner reports working ads and receipt of a rewarded credit in 0.2.0 (4). The live-unit 0.2.0 (5) archive was built and accepted by Apple in workflow 44620092863, source d669af8; five core tests and unsigned simulator/device validation 44620042528 passed. The exported IPA was inspected for live ad environment, correct iOS AdMob app ID, version/build, embedded SDK privacy manifests and signature files. SHA256: 2d6dc6f6d2845cd993801d7a1d77a4e5deff2dc140a8185512b96e8824d14ea4. This does not establish live ad fill on hardware.

The separate bilingual advertising policy is public and exact-content checked over HTTPS. App Store privacy was updated to nine data types and both localized policy links were saved. Details and purpose/linkage decisions are in PRIVACY-ADS-DRAFT.md (retained filename, now published). Existing website policies were preserved. No new Apple agreement appeared during the existing-declaration edits. No App Review submission was made.

Store draft version is now 0.2.0. English/Turkish descriptions disclose rewarded credits, non-personalized banners and occasional interstitials; obsolete ad-free App Review notes were replaced. The age questionnaire declares Advertising=Yes, no shared real-world location or dating features, and retains the owner-selected 18+ override. Store screenshots/content-rights and the final submission readiness pass remain separate; do not infer App Review approval from TestFlight availability.

Apple finished processing 0.2.0 (5); it was added to the existing Lanpixo Device Tests group and visibly showed Testing. Local proof: ios/qa/ads-live-build5-testing.jpg. The IPA has LanpixoAdEnvironment=live and uses the provided iOS units; release defaults outside the explicit live archive workflow remain test for safer development. No live-ad interaction was performed by the agent.
