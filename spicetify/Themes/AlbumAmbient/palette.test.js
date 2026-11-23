// Run: node palette.test.js
// Feeds synthetic 48x48 "covers" through buildPalette and checks readability.
const { buildPalette, contrast, hexToRgb, luminance } = require("./theme.js");

const SIZE = 48;
let seed = 7;
const rnd = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);

// parts: [[r,g,b,share], ...]; small per-pixel noise like a real image
function cover(parts) {
  const data = new Uint8ClampedArray(SIZE * SIZE * 4);
  const total = parts.reduce((s, p) => s + p[3], 0);
  for (let i = 0; i < SIZE * SIZE; i++) {
    let pick = rnd() * total, c = parts[0];
    for (const p of parts) { if ((pick -= p[3]) <= 0) { c = p; break; } }
    for (let k = 0; k < 3; k++) data[i * 4 + k] = Math.max(0, Math.min(255, c[k] + (rnd() - 0.5) * 24));
    data[i * 4 + 3] = 255;
  }
  return data;
}

const cases = {
  "dark (black + deep red)":   [[12, 10, 12, 70], [120, 20, 30, 30]],
  "bright (white + yellow)":   [[250, 250, 245, 55], [255, 220, 40, 45]],
  "warm (orange / red)":       [[240, 120, 30, 50], [200, 40, 40, 40], [250, 200, 120, 10]],
  "cool (blue / teal)":        [[30, 90, 200, 55], [20, 180, 190, 35], [10, 20, 60, 10]],
  "neon (magenta + cyan)":     [[255, 0, 200, 50], [0, 255, 255, 50]],
  "monochrome green":          [[40, 160, 70, 100]],
  "greyscale":                 [[30, 30, 30, 50], [200, 200, 200, 50]],
  "pure white":                [[255, 255, 255, 100]],
};

const WHITE = [255, 255, 255];
let failed = 0;
for (const [name, parts] of Object.entries(cases)) {
  const p = buildPalette(cover(parts));
  const rgb = Object.fromEntries(Object.entries(p).map(([k, v]) => [k, hexToRgb(v)]));
  const checks = {
    "valid hex": Object.values(p).every((v) => /^#[0-9a-f]{6}$/.test(v)),
    "white on primary >= 6": contrast(WHITE, rgb.primary) >= 6,
    "white on secondary >= 6": contrast(WHITE, rgb.secondary) >= 6,
    "accent on background >= 7": contrast(rgb.accent, rgb.background) >= 7,
    "background is very dark": luminance(rgb.background) < 0.01,
  };
  const bad = Object.entries(checks).filter(([, ok]) => !ok).map(([k]) => k);
  failed += bad.length;
  console.log(`${bad.length ? "FAIL" : "ok  "}  ${name.padEnd(26)} ${JSON.stringify(p)}${bad.length ? "  <- " + bad.join(", ") : ""}`);
}
console.log(failed ? `\n${failed} check(s) failed` : "\nAll checks passed");
process.exit(failed ? 1 : 0);
