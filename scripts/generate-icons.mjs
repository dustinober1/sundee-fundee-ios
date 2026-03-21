/**
 * generate-icons.mjs
 * Generates PWA icon PNGs from a simplified version of the favicon SVG.
 * Uses sharp with navy background (#0D1A40) for all icons.
 *
 * Usage: node scripts/generate-icons.mjs
 */

import { createRequire } from 'module';
import { mkdirSync } from 'fs';
import { resolve, dirname } from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const ROOT = resolve(__dirname, '..');

// Load sharp from pwa/node_modules where it is installed
const requireFromPwa = createRequire(resolve(ROOT, 'pwa/package.json'));
const sharp = requireFromPwa('sharp');

const ICONS_DIR = resolve(ROOT, 'pwa/public/icons');
const NAVY = { r: 13, g: 26, b: 64 };

// Simplified SVG with sRGB colors (no display-p3) for sharp/librsvg compatibility
const SIMPLIFIED_SVG = `<svg xmlns="http://www.w3.org/2000/svg" width="48" height="46" fill="none" viewBox="0 0 48 46">
  <rect width="48" height="46" fill="#0D1A40"/>
  <path fill="#863bff" d="M25.946 44.938c-.664.845-2.021.375-2.021-.698V33.937a2.26 2.26 0 0 0-2.262-2.262H10.287c-.92 0-1.456-1.04-.92-1.788l7.48-10.471c1.07-1.497 0-3.578-1.842-3.578H1.237c-.92 0-1.456-1.04-.92-1.788L10.013.474c.214-.297.556-.474.92-.474h28.894c.92 0 1.456 1.04.92 1.788l-7.48 10.471c-1.07 1.498 0 3.579 1.842 3.579h11.377c.943 0 1.473 1.088.89 1.83L25.947 44.94z"/>
</svg>`;

const icons = [
  { size: 192, output: resolve(ICONS_DIR, 'icon-192.png') },
  { size: 512, output: resolve(ICONS_DIR, 'icon-512.png') },
  { size: 180, output: resolve(ROOT, 'pwa/public/apple-touch-icon.png') },
];

// Ensure icons directory exists
mkdirSync(ICONS_DIR, { recursive: true });

async function generateIcons() {
  for (const { size, output } of icons) {
    await sharp(Buffer.from(SIMPLIFIED_SVG))
      .resize(size, size, { fit: 'contain', background: NAVY })
      .flatten({ background: NAVY })
      .png()
      .toFile(output);
    console.log(`Generated: ${output} (${size}x${size})`);
  }
  console.log('All icons generated successfully.');
}

generateIcons().catch((err) => {
  console.error('Icon generation failed:', err);
  process.exit(1);
});
