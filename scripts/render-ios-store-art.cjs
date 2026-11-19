// Rasterize repo-native SVG layouts without modifying their source screenshots.
const fs = require('fs');
const path = require('path');
const { Resvg } = require('../.tools/store-graphics/node_modules/@resvg/resvg-js');
const root = path.resolve(__dirname, '../ios/app-store/screenshots');
const entries = JSON.parse(fs.readFileSync(path.join(root, 'manifest.json'), 'utf8'));
for (const entry of entries) {
  const file = path.join(root, entry.svg);
  const renderer = new Resvg(fs.readFileSync(file), {
    font: { fontFiles: ['C:/Windows/Fonts/segoeui.ttf', 'C:/Windows/Fonts/segoeuib.ttf'], loadSystemFonts: false, defaultFontFamily: 'Segoe UI' }
  });
  fs.writeFileSync(file.replace(/\.svg$/, '.png'), renderer.render().asPng());
}
console.log('Rendered', entries.length, 'App Store PNG files');
