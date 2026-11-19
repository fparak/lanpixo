# Advertising privacy update — draft, not published

Applies to 0.2.0, Google Mobile Ads 13.13.0 and UMP. The published 0.1.0 answers in PRIVACY-DISCLOSURE.md describe the previous binary only.

## Data review

| Category | Source | Proposed purposes |
| --- | --- | --- |
| Other Data / Other Usage Data | Existing external speed-test requests | Functionality, Analytics |
| Coarse Location | Ad-request IP-derived location; OS location collection disabled | Third-party advertising, Analytics |
| Device IDs | SDK app/device identifiers; no ATT request, publisher first-party ID disabled | Third-party advertising, Analytics |
| Product Interaction / Advertising Data | Ad views, reward interactions and SDK events | Third-party advertising, Analytics |
| Crash Data | SDK diagnostics | Analytics |
| Performance / Other Diagnostic Data | SDK timing and diagnostics | Third-party advertising, Analytics |

Google's generic embedded manifest marks Device ID as potentially used for tracking. That capability is not by itself proof of runtime tracking in this restricted configuration. Review actual runtime configuration and Apple's definition before publishing tracking answers; do not assume non-personalized ads mean no collection, or silently reuse the prior ad-free answers. No scan inventory, recognized-device notes, contacts, GPS or payment information is passed to Google by application code. SDK coarse location can still be inferred from the network IP.

The app's embedded declaration is deliberately broad pending the release review; inspect the complete archive's SDK manifests as well. Do not claim a completed privacy audit or publish a live build solely on the basis of this draft.

## Before live release

1. Deploy the separate TR/EN policy `play-store/website/privacy/lanpixo-ios-ads.html` and verify HTTPS content.
2. Prepare updated App Store categories, linkage and tracking answers reflecting the complete archive and configuration. Update the listing policy URL and ad-related review information.
3. At Apple's final publish undertaking, obtain the owner's action-time approval of the concrete revised declaration. The previous approval covered 0.1.0 without ads.

Reviewed primary sources on 19 November 2026:

- https://developers.google.com/admob/ios/privacy/data-disclosure
- https://developers.google.com/admob/ios/privacy/strategies
- https://developer.apple.com/app-store/app-privacy-details/

The owner reported that the iOS app was added to the published AdMob European message. This is owner-reported, not independently verified in the AdMob console. Real-device consent/ad tests remain necessary.
