/**
 * AlbumAmbient — companion script (Spicetify theme.js)
 *
 * Single responsibility: read the current track's cover art, derive a small
 * palette, and write four CSS custom properties on <html>:
 *   --album-primary  --album-secondary  --album-accent  --album-background
 * All visuals, gradients and transitions live in user.css.
 */
(function () {
  "use strict";

  const SIZE = 48; // cover is downscaled to SIZE x SIZE before analysis
  const HUE_BUCKETS = 24; // 15 degrees each

  const DEFAULT_PALETTE = {
    primary: "#2b2b52",
    secondary: "#3d2a4f",
    accent: "#9aa3e0",
    background: "#0a0a12",
  };

  /* ------------------------------ colour maths ----------------------------- */

  const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

  function rgbToHsl(r, g, b) {
    r /= 255; g /= 255; b /= 255;
    const max = Math.max(r, g, b), min = Math.min(r, g, b);
    const l = (max + min) / 2, d = max - min;
    let h = 0, s = 0;
    if (d > 0) {
      s = d / (1 - Math.abs(2 * l - 1));
      if (max === r) h = ((g - b) / d) % 6;
      else if (max === g) h = (b - r) / d + 2;
      else h = (r - g) / d + 4;
      h *= 60;
      if (h < 0) h += 360;
    }
    return [h, s, l];
  }

  function hslToRgb(h, s, l) {
    h = ((h % 360) + 360) % 360;
    const c = (1 - Math.abs(2 * l - 1)) * s;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = l - c / 2;
    let rgb;
    if (h < 60) rgb = [c, x, 0];
    else if (h < 120) rgb = [x, c, 0];
    else if (h < 180) rgb = [0, c, x];
    else if (h < 240) rgb = [0, x, c];
    else if (h < 300) rgb = [x, 0, c];
    else rgb = [c, 0, x];
    return rgb.map((v) => Math.round(clamp(v + m, 0, 1) * 255));
  }

  const toHex = (rgb) => "#" + rgb.map((v) => v.toString(16).padStart(2, "0")).join("");
  const hexToRgb = (hex) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));

  function luminance(rgb) {
    const f = (v) => {
      v /= 255;
      return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    };
    return 0.2126 * f(rgb[0]) + 0.7152 * f(rgb[1]) + 0.0722 * f(rgb[2]);
  }

  function contrast(a, b) {
    const la = luminance(a), lb = luminance(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
  }

  const hueDistance = (a, b) => {
    const d = Math.abs(a - b) % 360;
    return d > 180 ? 360 - d : d;
  };

  /* ----------------------------- palette building -------------------------- */

  /** Find the dominant and a distinct secondary hue in raw RGBA pixel data. */
  function analyse(data) {
    const buckets = Array.from({ length: HUE_BUCKETS }, () => ({ w: 0, sin: 0, cos: 0, s: 0, l: 0 }));
    let neutralWeight = 0;

    for (let i = 0; i < data.length; i += 4) {
      if (data[i + 3] < 200) continue;
      const [h, s, l] = rgbToHsl(data[i], data[i + 1], data[i + 2]);
      const mid = 1 - Math.abs(2 * l - 1); // 0 at black/white, 1 at mid-lightness

      if (s < 0.14 || l < 0.06 || l > 0.94) {
        neutralWeight += 0.05 + 0.1 * mid;
        continue;
      }
      const w = s * mid + 0.01; // favour colourful, mid-tone pixels
      const b = buckets[Math.floor(h / (360 / HUE_BUCKETS)) % HUE_BUCKETS];
      const rad = (h * Math.PI) / 180;
      b.w += w;
      b.sin += Math.sin(rad) * w;
      b.cos += Math.cos(rad) * w;
      b.s += s * w;
      b.l += l * w;
    }

    const chromaticWeight = buckets.reduce((sum, b) => sum + b.w, 0);
    if (chromaticWeight === 0 || chromaticWeight < neutralWeight) return { grey: true };

    const cands = buckets
      .map((b, i) => {
        if (!b.w) return null;
        const prev = buckets[(i + HUE_BUCKETS - 1) % HUE_BUCKETS].w;
        const next = buckets[(i + 1) % HUE_BUCKETS].w;
        let h = (Math.atan2(b.sin, b.cos) * 180) / Math.PI;
        if (h < 0) h += 360;
        return { h, s: b.s / b.w, l: b.l / b.w, score: b.w + 0.5 * (prev + next), w: b.w };
      })
      .filter(Boolean)
      .sort((a, b) => b.score - a.score);

    const primary = cands[0];
    const secondary = cands.find((c) => hueDistance(c.h, primary.h) >= 35 && c.w >= primary.w * 0.25) || null;
    return { grey: false, primary, secondary };
  }

  /** Darken a colour until white text on it reaches the contrast target. */
  function fitSurface(h, s, l) {
    let rgb = hslToRgb(h, s, l);
    while (contrast(rgb, [255, 255, 255]) < 6 && l > 0.08) {
      l -= 0.01;
      rgb = hslToRgb(h, s, l);
    }
    return rgb;
  }

  /** Lighten a colour until it reaches the contrast target on the background. */
  function fitAccent(h, s, l, bgRgb) {
    let rgb = hslToRgb(h, s, l);
    while (contrast(rgb, bgRgb) < 7 && l < 0.92) {
      l += 0.02;
      rgb = hslToRgb(h, s, l);
    }
    return rgb;
  }

  /** Raw RGBA pixel array -> palette of four hex colours. */
  function buildPalette(data) {
    const found = analyse(data);
    let h1, s1, h2, s2, bgS;

    if (found.grey) {
      h1 = 230; s1 = 0.06; h2 = 230; s2 = 0.05; bgS = 0.05;
    } else {
      h1 = found.primary.h;
      s1 = clamp(found.primary.s, 0.28, 0.6); // avoid over-saturation
      if (found.secondary) {
        h2 = found.secondary.h;
        s2 = clamp(found.secondary.s, 0.22, 0.55);
      } else {
        h2 = h1 + 40; // analogous fallback when the cover is monochrome
        s2 = s1 * 0.9;
      }
      bgS = 0.35;
    }

    const bgRgb = hslToRgb(h1, bgS, 0.06);
    const primary = fitSurface(h1, s1, 0.34);
    const secondary = fitSurface(h2, s2, 0.28);
    const accentS = found.grey ? 0.06 : clamp(s1 * 0.9, 0.3, 0.6);
    const accent = fitAccent(h1, accentS, 0.66, bgRgb);

    return {
      primary: toHex(primary),
      secondary: toHex(secondary),
      accent: toHex(accent),
      background: toHex(bgRgb),
    };
  }

  /* ------------------------------ Spotify glue ----------------------------- */

  const cache = new Map();
  let lastUrl = Symbol("none");
  let token = 0;

  function paletteFromImage(img) {
    const canvas = document.createElement("canvas");
    canvas.width = canvas.height = SIZE;
    const ctx = canvas.getContext("2d", { willReadFrequently: true });
    ctx.drawImage(img, 0, 0, SIZE, SIZE);
    return buildPalette(ctx.getImageData(0, 0, SIZE, SIZE).data);
  }

  function toUrl(uri) {
    if (!uri) return null;
    if (/^https?:/.test(uri)) return uri;
    const m = /^spotify:image:([a-f0-9]+)$/i.exec(uri);
    return m ? "https://i.scdn.co/image/" + m[1] : null; // local files -> null -> default
  }

  /** Returns a URI, null (no art) or undefined (ad: keep the current palette). */
  function currentArtUri() {
    const d = Spicetify.Player.data;
    const item = d && (d.item || d.track);
    const md = item && item.metadata;
    if (!md) return null;
    if (md.is_advertisement === "true") return undefined;
    return md.image_url || md.image_large_url || md.image_xlarge_url || md.image_small_url || null;
  }

  function loadImage(url) {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.crossOrigin = "anonymous";
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = url;
    });
  }

  function apply(p, state) {
    const root = document.documentElement;
    root.style.setProperty("--album-primary", p.primary);
    root.style.setProperty("--album-secondary", p.secondary);
    root.style.setProperty("--album-accent", p.accent);
    root.style.setProperty("--album-background", p.background);
    root.dataset.albumAmbient = state;
  }

  async function update() {
    const art = currentArtUri();
    if (art === undefined) return;
    const url = toUrl(art);
    if (url === lastUrl) return;
    lastUrl = url;

    const mine = ++token;
    let palette = DEFAULT_PALETTE;
    if (url) {
      palette = cache.get(url);
      if (!palette) {
        try {
          const img = await loadImage(url);
          if (mine !== token) return; // a newer track superseded this one
          palette = paletteFromImage(img);
          cache.set(url, palette);
          if (cache.size > 60) cache.delete(cache.keys().next().value);
        } catch (e) {
          palette = DEFAULT_PALETTE;
        }
      }
    }
    if (mine !== token) return;
    apply(palette, url ? "art" : "fallback");
  }

  function boot() {
    if (!(window.Spicetify && Spicetify.Player && typeof Spicetify.Player.addEventListener === "function")) {
      setTimeout(boot, 300);
      return;
    }
    Spicetify.Player.addEventListener("songchange", () => update().catch(() => {}));
    update().catch(() => {});
  }

  if (typeof module !== "undefined" && module.exports) {
    module.exports = { buildPalette, contrast, hexToRgb, luminance, DEFAULT_PALETTE };
  } else {
    boot();
  }
})();
