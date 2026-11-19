# Advertising privacy update — published 20 November 2026

Applies to 0.2.0, Google Mobile Ads 13.13.0 and UMP. The 0.1.0 answers in PRIVACY-DISCLOSURE.md describe the previous binary only. The owner requested the advertising privacy update after reporting working ads and reward credit on hardware. App Store Connect confirmed publication of all nine categories; no new agreement/undertaking dialog appeared during these existing-declaration edits.

## Data review

| Category | Source | Proposed purposes |
| --- | --- | --- |
| Other Data / Other Usage Data | Existing external speed-test requests | Functionality, Analytics |
| Coarse Location | Ad-request IP-derived location; OS location collection disabled | Third-party advertising, Analytics, Functionality |
| Device IDs | SDK app/device identifiers; no ATT request, publisher first-party ID disabled | Third-party advertising, Analytics, Functionality |
| Product Interaction / Advertising Data | Ad views, reward interactions and SDK events | Third-party advertising, Analytics, Functionality |
| Crash Data | SDK diagnostics | Analytics |
| Performance / Other Diagnostic Data | SDK timing and diagnostics | Third-party advertising, Analytics, Functionality |

Google's generic embedded manifest marks Device ID as potentially used for tracking. The app requests only non-personalized ads, disables publisher personalization and first-party ID, requests no ATT/IDFA access, supplies no cross-app targeting data and has no mediation adapters. The label declares no tracking for this restricted configuration. This is a configuration-based assessment, not a network audit of Google's services; reassess before enabling personalized ads, ATT, mediation or additional identifiers. Non-personalized ads still collect data. No scan inventory, recognized-device notes, contacts, GPS or payment information is passed to Google by application code. Coarse location can still be inferred from the network IP.

Crash Data and Other Diagnostic Data are declared not linked, consistent with the SDK's manifest. The remaining seven types are conservatively declared linked, including performance data described as user-associated by Google's disclosure. Functionality includes fraud prevention and technical reliability. The application manifest matches these answers; original signed SDK manifests remain embedded and unchanged. This is not a completed third-party privacy audit.

## Published policy and evidence

The separate TR/EN policy is public at https://epx-studio.com/privacy/lanpixo-ios-ads.html . HTTPS returned 200 and its content exactly matched the local generated file. App Store Connect English and Turkish policy URLs now use this document (Turkish #tr). Existing Android and ad-free iOS policies were preserved. Local proof: qa/privacy-ads-published-20261120.jpg and qa/privacy-ads-policy-live.jpg. Store submission/review notes and screenshots require their own final release pass; no App Review submission was made here.

Reviewed primary sources on 19–20 November 2026:

- https://developers.google.com/admob/ios/privacy/data-disclosure
- https://developers.google.com/admob/ios/privacy/strategies
- https://developer.apple.com/app-store/app-privacy-details/

The owner reported that the iOS app was added to the published AdMob European message, and subsequently reported working ads and receipt of a reward credit on 20 November. These are owner-reported, not independently observed in the console or on hardware. Live fill remains dependent on AdMob readiness and user consent.
