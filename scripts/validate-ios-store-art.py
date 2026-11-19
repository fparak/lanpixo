"""Validate store dimensions/provenance and remove an entirely opaque alpha channel."""
from pathlib import Path
import hashlib, json
from PIL import Image

root = Path(__file__).resolve().parents[1] / 'ios/app-store/screenshots'
entries = json.loads((root / 'manifest.json').read_text(encoding='utf-8'))
assert len(entries) == 12
for item in entries:
    source = Path(item['source'])
    if not source.is_absolute(): source = Path(__file__).resolve().parents[1] / source
    assert hashlib.sha256(source.read_bytes()).hexdigest() == item['sourceSHA256']
    path = (root / item['svg']).with_suffix('.png')
    with Image.open(path) as image:
        assert image.size == (item['width'], item['height'])
        assert image.size in [(1206,2622),(2064,2752)]
        if 'A' in image.getbands():
            assert image.getchannel('A').getextrema() == (255,255), path
            rgb = image.convert('RGB')
        else:
            rgb = image.convert('RGB')
    rgb.save(path)
    with Image.open(path) as check: assert check.mode == 'RGB'
print('PASS: 12 correctly sized RGB screenshots, opaque backgrounds and source hashes')
