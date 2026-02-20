/**
 * PWA Icon Generation Script
 *
 * Generates 4 PNG icons for Sundee-Fundee PWA:
 *   - icon-192.png          (192×192) standard Android icon
 *   - icon-192-maskable.png (192×192) full-bleed maskable variant
 *   - icon-512.png          (512×512) Chrome install prompt icon
 *   - apple-touch-icon.png  (180×180) iOS home screen icon
 *
 * Run: node scripts/generate-icons.mjs
 */

import sharp from 'sharp';
import { mkdir } from 'fs/promises';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ICONS_DIR = resolve(__dirname, '../public/icons');

// SVG source for standard icons (192, 512, apple-touch)
// Dark #171717 background with 80px corner radius, white "SF" monogram
const standardSvg = (size) => {
  const rx = Math.round(80 * (size / 512));
  const fontSize = Math.round(220 * (size / 512));
  const y = Math.round(340 * (size / 512));
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="${size}" height="${size}" rx="${rx}" fill="#171717"/>
  <text x="${size / 2}" y="${y}" font-family="system-ui, -apple-system, sans-serif"
    font-size="${fontSize}" font-weight="700" fill="white" text-anchor="middle">SF</text>
</svg>`);
};

// SVG source for maskable icon (no rx, text scaled to 75% safe zone)
// Full-bleed background, smaller text to stay within inner safe area
const maskableSvg = (size) => {
  const fontSize = Math.round(180 * (size / 512));
  const y = Math.round(330 * (size / 512));
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
  <rect width="${size}" height="${size}" fill="#171717"/>
  <text x="${size / 2}" y="${y}" font-family="system-ui, -apple-system, sans-serif"
    font-size="${fontSize}" font-weight="700" fill="white" text-anchor="middle">SF</text>
</svg>`);
};

const icons = [
  {
    filename: 'icon-192.png',
    size: 192,
    svgFn: standardSvg,
    description: 'Standard Android icon',
  },
  {
    filename: 'icon-192-maskable.png',
    size: 192,
    svgFn: maskableSvg,
    description: 'Maskable Android icon (full-bleed)',
  },
  {
    filename: 'icon-512.png',
    size: 512,
    svgFn: standardSvg,
    description: 'Chrome install prompt icon',
  },
  {
    filename: 'apple-touch-icon.png',
    size: 180,
    svgFn: standardSvg,
    description: 'iOS home screen icon',
  },
];

async function generateIcons() {
  // Ensure output directory exists
  await mkdir(ICONS_DIR, { recursive: true });

  console.log(`Generating icons in ${ICONS_DIR}\n`);

  for (const icon of icons) {
    const outputPath = resolve(ICONS_DIR, icon.filename);
    const svgBuffer = icon.svgFn(icon.size);

    await sharp(svgBuffer)
      .png()
      .toFile(outputPath);

    const stats = await import('fs').then(fs =>
      fs.promises.stat(outputPath)
    );
    const sizeKb = (stats.size / 1024).toFixed(1);

    console.log(`✓ ${icon.filename} (${icon.size}×${icon.size}) — ${sizeKb}KB — ${icon.description}`);
  }

  console.log('\nDone! All 4 icons generated successfully.');
}

generateIcons().catch(err => {
  console.error('Error generating icons:', err);
  process.exit(1);
});
