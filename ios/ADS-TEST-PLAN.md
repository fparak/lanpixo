# iOS 0.2.0 advertising verification

Google Mobile Ads is pinned to 13.13.0. Debug and Release default to Google test units. The signed workflow requires an explicit `ads_mode=live` to use the owner's iOS units. An unknown or missing build setting remains in test mode. Android configuration is separate.

## Physical iPhone / iPad checks

Use TestFlight 0.2.0 (4). These are pending owner verification; a successful compile is not proof of ad delivery.

1. Open Settings. Complete a consent message if geographically applicable. Consent failure must leave basic discovery usable. Retry consent in Settings. Where required, reopen Ad privacy choices and verify changes persist.
2. In History and Settings, verify the banner says Test Ad and fits portrait and landscape without covering navigation. No banner should appear over an active network or speed measurement.
3. In Settings, choose Test rewarded ad. Close early: no credit. Watch to the SDK's reward: exactly one credit. Close the ad and relaunch: the credit remains. These manual test controls are absent in live mode.
4. Scan an authorized Wi-Fi, open a discovered device and run the extended check. It costs one credit on completion. Cancel, background the app, or interrupt the process during the check: the reservation must be refunded once. Basic discovery and the original 16-port check remain free with zero credits.
5. In Settings, choose Test interstitial ad. Verify display and return to the app. Natural interstitials require leaving completed Network results, at least three completed checks and 180 seconds since the last full-screen ad. They must not interrupt an active scan or follow a reward immediately.
6. Disable connectivity. Failed ad requests must not deduct credit or prevent local network discovery when Wi-Fi is available again. Never click live ads for testing.

## Release gates

- Actual banner, rewarded completion/early dismissal, interstitial and credit recovery verified on hardware.
- Publish the separate bilingual `play-store/website/privacy/lanpixo-ios-ads.html` draft, preserving the ad-free 0.1.0 policy.
- Replace the old ad-free App Store privacy declarations and review notes with disclosures reflecting Google SDK data. The old declaration does not cover this version. Review the SDK manifest alongside runtime restrictions; non-personalized does not mean no collection.
- Refresh store screenshots if visible UI changes affect the listing. Do not label the existing 0.1.0 captures as 0.2.0.
- Build a subsequent signed live-unit version only after the above checks. Actual fill depends on AdMob application/account/ad-unit readiness.

## Automated evidence

- Initial advertising integration: workflow 44611913876, commit b212aa3, simulator + unsigned device builds passed; five core tests passed.
- Hardened consent lifecycle, manual test controls and adaptive banner sizing: commit 88ed3d7. Validation 44612623009; iPhone/iPad UI 44612623079; signed test-ad upload 44612687608. Check final workflow conclusions before reporting success.

References: https://developers.google.com/admob/ios/privacy , https://developers.google.com/admob/ios/privacy/data-disclosure , https://developers.google.com/admob/ios/test-ads .

Signed workflow 44612687608 and validation 44612623009 succeeded. Apple accepted delivery 2baa3b14-9914-4b15-a1c5-c2788f9a8dc9. The existing internal test group shows 0.2.0 (4) as Testing. Local archive metadata confirms test mode and SDK privacy manifests; physical ad presentation remains pending.

UI workflow 44612623079: all three iPad cases and all three iPhone cases passed (English/light, Turkish/dark, accessibility text, portrait/landscape navigation). iPad screenshot en-04-settings-portrait visibly contains the genuine Google Adaptive Banner with Test mode label. This verifies simulator banner delivery and layout, not physical rewarded completion.
