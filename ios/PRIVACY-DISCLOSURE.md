# iOS 0.1.0 privacy disclosure

This applies to the native iOS build without advertising, purchases, analytics SDKs or account registration. It does not copy Android's AdMob disclosures.

Public policy: https://epx-studio.com/privacy/lanpixo-ios.html (TR and EN).

## Data flow reviewed

| Flow | Destination | Disclosure |
| --- | --- | --- |
| Discovery TCP / Bonjour | The user's local Wi-Fi devices | No EPX server upload; device inventory and recognition notes stay in UserDefaults. |
| Optional HTTPS speed measurement | fra.speedtest.clouvider.net | Public IP, normal HTTP metadata and request timing/size are visible to the service. No inventory, recognition notes or completed speed-result history is uploaded. |
| CSV export | User-selected Files destination | User controls the location; a selected cloud provider may receive the file. |
| Support email | User's mail app, then EPX if the user sends it | No automatic in-app feedback upload or attachment. |
| Local backup | iOS / user's backup provider | User-controlled platform backup may contain app preferences. |

## App Store Connect responses

- Other Data Types: public IP and normal connection metadata.
- Other Usage Data: service requests / timing and frequency, not screen-tap telemetry.
- Purposes: App Functionality and Analytics. This is a conservative declaration covering Clouvider's published general service policy, which permits service analysis and security use. No endpoint-specific immediate-deletion guarantee was found.
- Linked to user: Yes. No pre-collection IP anonymization is established.
- Used for tracking: No. No IDFA, advertising SDK, retargeting or data-broker integration in this app.
- Do not declare local inventory as off-device collection or claim MAC/GPS/contacts are collected.
- IP-derived location is possible, but this app does not request, derive or submit a location field; no endpoint-specific geolocation behavior was established.

The provider's general website cookie/marketing policy does not establish that its website JavaScript or cookies execute inside the app. BoundedHTTP uses ephemeral URLSession without cookie storage; it does not load the website or a web view.

Sources checked 19 November 2026:

- https://developer.apple.com/app-store/app-privacy-details/
- https://www.clouvider.com/privacy-and-cookies-policy/

Apple defines collection as access beyond servicing a real-time request. Because retention at the external endpoint is unverified, do not select “No data collected.” These are conservative declarations, not an audit of the external server's logs. Reassess if the endpoint, ads, purchases or telemetry changes.

The owner explicitly approved Apple's accuracy/compliance/update undertaking. The responses were published on 19 November 2026; App Store Connect showed “Published … by Fatih Parak.” Both English and Turkish policy URLs were saved. Local proof: `qa/privacy-published-20261119.jpg`.

Build 3's embedded PrivacyInfo.xcprivacy also declares these two data types with linked=true, tracking=false, App Functionality and Analytics purposes. UserDefaults retains required-reason CA92.1. No tracking domains are declared. Info.plist declares no non-exempt encryption; the app only uses the operating system's HTTPS implementation.
