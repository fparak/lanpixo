"""Compose vector App Store artwork around unaltered XCTest screenshots.

Usage: python scripts/build-ios-store-art.py PHONE_ARTIFACT IPAD_ARTIFACT
Inputs are extracted artifacts containing ui-screenshots/manifest.json.
No sample devices or fabricated speed results are added.
"""
from pathlib import Path
import base64, hashlib, html, json, sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'ios/app-store/screenshots'
COPY = {
    'en': [(['Meet your', 'Wi-Fi network.'], 'Discover responding devices on your Wi-Fi.', '01-network'),
           (['A quick check.', 'A clearer connection.'], 'Estimate transfer speed over HTTPS.', '02-speed'),
           (['Your app.', 'Your preferences.'], 'Choose your language, theme and local records.', '04-settings')],
    'tr': [(['Wi-Fi ağını', 'keşfet.'], 'Ağında yanıt veren cihazları keşfet.', '01-network'),
           (['Bağlantını', 'yakından tanı.'], 'HTTPS ile aktarım hızını tahmin et.', '02-speed'),
           (['Tercihlerin', 'senin elinde.'], 'Dilini, temanı ve yerel kayıtlarını yönet.', '04-settings')]
}
manifest = []
for family, artifact in zip(['iphone', 'ipad'], sys.argv[1:]):
    origin = Path(artifact) / 'ui-screenshots'
    entries = [a for test in json.loads((origin / 'manifest.json').read_text(encoding='utf-8')) for a in test['attachments']]
    for language, frames in COPY.items():
        locale = 'en-US' if language == 'en' else 'tr'
        directory = OUT / locale / family
        directory.mkdir(parents=True, exist_ok=True)
        for index, (lines, subtitle, screen) in enumerate(frames, 1):
            prefix = f'{language}-{screen}-portrait_'
            candidates = [e for e in entries if e['suggestedHumanReadableName'].startswith(prefix)]
            assert len(candidates) == 1, (family, prefix, len(candidates))
            entry = candidates[0]
            source = origin / entry['exportedFileName']
            with Image.open(source) as image:
                sw, sh = image.size
                assert sw < sh
            # Apple's required medium Dynamic Island canvas and 13-inch iPad.
            # Preserve the source screenshot's aspect ratio inside each card.
            w, h = (1206, 2622) if family == 'iphone' else (2064, 2752)
            x, y, iw = (144, 565, 918) if family == 'iphone' else (232, 560, 1600)
            ih = iw * sh / sw
            assert y + ih < h - 35
            uri = 'data:image/png;base64,' + base64.b64encode(source.read_bytes()).decode()
            title_size = 82 if family == 'iphone' else 110
            left = 96 if family == 'iphone' else 144
            title_y = 280 if family == 'iphone' else 290
            line_height = 100 if family == 'iphone' else 122
            title = ''.join(f'<text x="{left}" y="{title_y+i*line_height}" font-size="{title_size}" font-weight="700" fill="#FFF8EE">{html.escape(line)}</text>' for i,line in enumerate(lines))
            sub_y = title_y + line_height + 90
            svg = f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{w}" height="{h}" viewBox="0 0 {w} {h}">
<defs><linearGradient id="bg" x2="0.8" y2="1"><stop stop-color="#111C2B"/><stop offset="1" stop-color="#080D15"/></linearGradient></defs>
<rect width="{w}" height="{h}" fill="url(#bg)"/>
<circle cx="{w}" cy="0" r="580" fill="none" stroke="#FF674E" stroke-opacity="0.12" stroke-width="2"/>
<circle cx="{w}" cy="0" r="430" fill="none" stroke="#FF674E" stroke-opacity="0.12" stroke-width="2"/>
<g font-family="Segoe UI, sans-serif">
<path d="M {left+7} 81 V 137 H {left+48}" fill="none" stroke="#FF674E" stroke-width="9" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="{left+7}" cy="81" r="7" fill="#FF674E"/><circle cx="{left+48}" cy="137" r="7" fill="#FF674E"/>
<text x="{left+78}" y="126" font-size="50" font-weight="700" fill="#FFF8EE">Lanpixo</text>
<text x="{w-left}" y="126" text-anchor="end" font-size="28" letter-spacing="4" fill="#FF927F">EPX STUDIO</text>
{title}
<text x="{left}" y="{sub_y}" font-size="32" fill="#B9C3D0">{html.escape(subtitle)}</text>
</g>
<rect x="{x-3}" y="{y-3}" width="{iw+6}" height="{ih+6}" rx="5" fill="#506070"/>
<image x="{x}" y="{y}" width="{iw}" height="{ih}" xlink:href="{uri}"/>
</svg>'''
            path = directory / f'{index:02d}-{screen.split("-",1)[1]}.svg'
            path.write_text(svg, encoding='utf-8')
            manifest.append({'svg': str(path.relative_to(OUT)), 'width':w, 'height':h,
                             'source':str(source.resolve().relative_to(ROOT)), 'sourceSHA256':hashlib.sha256(source.read_bytes()).hexdigest(),
                             'device':entry['deviceName'], 'testScreen':entry['suggestedHumanReadableName'],
                             'scope':'Actual UI screenshot, editorial caption; no discovery/measurement result fabricated'})
(OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
print('Created', len(manifest), 'vector store cards')
