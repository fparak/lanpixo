# Store assets

12 localized screenshots were uploaded to App Store Connect: three English and three Turkish screens for both iPhone and iPad. Local export: `releases/lanpixo-ios-store-assets.zip` from the workspace root. Generated images are local delivery artifacts and are also saved in App Store Connect; this repository contains the source generators and provenance manifest.

Canvas sizes follow Apple's required medium Dynamic Island iPhone (1206×2622) and 13-inch iPad (2064×2752) slots. The native screenshot is scaled proportionally within each vector card, never cropped or given invented inventory or measurement data. English uses the actual light UI; Turkish uses the actual dark UI.

To reproduce on Windows, download/extract the phone and iPad screenshot artifacts from workflow 44442330758, or run `ios-ui.yml` again for fresh captures of the current app. CI artifacts have limited retention; retain a local copy when needed.

```powershell
npm install --prefix .tools/store-graphics @resvg/resvg-js --no-save --ignore-scripts
python scripts/build-ios-store-art.py ios/qa/phone-ui-3 ios/qa/ipad-ui-3
node scripts/render-ios-store-art.cjs
python scripts/validate-ios-store-art.py
```

The validator removes an entirely opaque alpha channel, checks RGB output, canvas dimensions and source SHA256 values. It rejects transparency instead of hiding it. Segoe UI font files come from the Windows installation. The SVGs remain editable code-native layouts; all screenshots inside them are actual XCTest attachments.

App Store Connect screenshot uploads save automatically. Each of the four language/device combinations was verified after a page reload to show three custom screenshots rather than inherited placeholders. No review submission was made.
