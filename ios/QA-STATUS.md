# iOS QA — 19 November 2026

## Current release preparation — build 3

See `RELEASE-PREPARATION.md` for the current scope and evidence. Build 3 was Apple-signed, exported and accepted by Apple's upload service. The iOS privacy policy is public, App Privacy responses are published with owner approval, and all 12 localized iPhone/iPad screenshots were uploaded and verified after reloading App Store Connect. iPad and iPhone simulator UI suites each passed three cases; stable landscape capture was separately rechecked on iPad. Physical-device network results remain deferred to the owner. Historical notes below describe earlier builds and attempts.

## Latest — build 2 uploaded

- Source `a5f34ce8a752230a9aca80bfc12e555dc2d84eb1`; macOS validation https://github.com/fparak/lanpixo/actions/runs/44437906144 passed. Compiler isolation warnings from the initial run were resolved; only the no-AppIntents metadata notice remains.
- Apple-signed archive/export, three XCTest cases and **upload** succeeded: https://github.com/fparak/lanpixo/actions/runs/44438062278 . Apple accepted 0.1.0 (2) at 01:43:50 UTC on 19 November 2026, delivery UUID `5c1433a1-b79f-4b24-a845-c99a2e926328`.
- One non-blocking server notice: this build uses iOS 26.5 SDK; Apple requires iOS 27 SDK from April 2027. Current upload was accepted.
- Local signed IPA `../releases/lanpixo-ios-0.1.0-2.ipa`, SHA256 `92bac1830fd4dbf18674ba2733e91dde71255a04ed4fec8a958d35feb2185496`; manifest `qa/signed-ipa-2.json`.
- Permission dialogs no longer cancel the operation merely by making the scene inactive; actual backgrounding still cancels. Cancelled port probes and old Bonjour callbacks cannot mutate a later run.
- iPhone simulator EN/light and TR/dark launch images inspected: `qa/run2/iphone-en-light.png`, `qa/run2/iphone-tr-dark.png`. These show an empty initial inventory, not a real-network scan. Run 2 was cancelled while its subsequent simulator step stalled; it is **not** an all-green UI suite. Revised sequential phone/iPad run 3 (44437374319) also failed in simulator launch/screenshot timeout after its core tests and both builds passed; iPad UI validation remains incomplete.
- App Store Connect record created; both EN/TR descriptions and review contact saved and reloaded to verify persistence. Utilities category, content-rights declaration and 18+ override saved. Questionnaire calculated 4+ before the owner's target-age override.
- Distribution certificate, app-specific profile and upload API key were created with explicit owner approvals. All six signing/upload secrets were saved only in `fparak/lanpixo` Actions Secrets. No key content or export password is committed. Public source: https://github.com/fparak/lanpixo .
- Separate iOS privacy HTML draft: `../play-store/website/privacy/lanpixo-ios.html`; public deployment still required before App Review.

Earlier “pending/upload not claimed” notes below refer to the initial build, not the completed build-2 upload. Apple processing/TestFlight usability, actual iPhone network tests, final store assets/privacy/compliance and App Review remain to be verified separately.

## Verified

- Source pushed to https://github.com/fparak/lanpixo . Repository is public; no signing material is committed.
- First macOS CI run: https://github.com/fparak/lanpixo/actions/runs/44435293298 . Xcode 26.6 (17F113).
- Three real XCTest cases passed: subnet edge cases, invalid/unsafe range rejection, CSV quoting/formula-injection handling.
- iOS Simulator Debug and iPhoneOS Release **unsigned** builds succeeded.
- Second run adds actor-isolation hardening and iPhone/iPad simulator launch screenshots: https://github.com/fparak/lanpixo/actions/runs/44435695495 . Later cancelled during simulator smoke; inspected iPhone images are recorded above.
- Windows static Swift syntax, PBX references, plist/privacy declarations, Bonjour service type parity, scheme and opaque 1024px icon checks passed.
- Clouvider endpoint checked over HTTPS from this Windows workstation: empty response 0 bytes, `ckSize=4` response exactly 4,194,304 bytes, 1,000,000-byte POST accepted with empty response. This is endpoint compatibility evidence, not an iPhone speed benchmark.
- Apple bundle ID registered for team M64GVYHN8L; App Store Connect draft created, app ID 6836586066. English metadata and version 0.1.0 saved.

## Still required

- Apple accepted signed build 2; TestFlight UI now shows upload Processing. Wait for processing and resolve any build-specific compliance prompts before installation.
- Inspect actual simulator screenshots and test additional screens, Dynamic Type, iPad rotation, VoiceOver and language changes.
- Actual iPhone Local Network permission allow/deny/re-enable, scan-vs-router comparison, cancellation, network changes and speed measurement. Simulator/source/CI do not establish these.
- Separate public iOS privacy policy, final App Privacy/age/export compliance, review contact phone, genuine store screenshots and review submission. Android advertising policy/SDK declarations must not be copied into this initial ad-free iOS build.
- Port iOS-specific AdMob + consent and monetization after separate iOS ad IDs and privacy declarations are configured. Initial iOS source has no ad/purchase SDK.

No signed IPA, TestFlight install or App Store release is claimed by the initial unsigned CI result.

Latest browser observation: TestFlight Build Uploads lists 0.1.0 (2) as Processing. Proof: qa/testflight-uploaded-20261119.jpg. No tester invitation or App Review submission was sent.
