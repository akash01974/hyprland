// Monet — Material You dynamic color for Spotify.
// Seed color comes from the current cover art; a Material-3-style tonal
// palette (OKLCH) is generated and applied live, with smooth transitions.
(function Monet() {
  if (!(Spicetify?.Player && Spicetify?.colorExtractor)) {
    setTimeout(Monet, 300);
    return;
  }

  const root = document.documentElement;

  /* ---------- color math (sRGB <-> OKLCH) ---------- */
  const toLin = (v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
  const toGam = (v) => (v <= 0.0031308 ? 12.92 * v : 1.055 * v ** (1 / 2.4) - 0.055);

  function hexToOklch(hex) {
    const n = parseInt(hex.replace("#", ""), 16);
    const r = toLin(((n >> 16) & 255) / 255), g = toLin(((n >> 8) & 255) / 255), b = toLin((n & 255) / 255);
    const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    const L = 0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s;
    const A = 1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s;
    const B = 0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s;
    return { L, C: Math.hypot(A, B), h: ((Math.atan2(B, A) * 180) / Math.PI + 360) % 360 };
  }

  function oklchRaw(L, C, h) {
    const a = C * Math.cos((h * Math.PI) / 180), b = C * Math.sin((h * Math.PI) / 180);
    const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3;
    const m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3;
    const s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3;
    return [
      4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
      -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s,
    ];
  }

  // Shrink chroma until the color fits in sRGB, then return [r,g,b] 0-255
  function tone(L, C, h) {
    let c = C, rgb = oklchRaw(L, c, h);
    for (let i = 0; i < 24 && rgb.some((v) => v < -0.001 || v > 1.001); i++) {
      c *= 0.9;
      rgb = oklchRaw(L, c, h);
    }
    return rgb.map((v) => Math.round(Math.min(1, Math.max(0, toGam(Math.max(0, v)))) * 255));
  }
  const hex = ([r, g, b]) => "#" + [r, g, b].map((v) => v.toString(16).padStart(2, "0")).join("");

  /* ---------- Material 3 scheme from a seed ---------- */
  function scheme(seedHex, dark) {
    const { C, h } = hexToOklch(seedHex);
    const cp = Math.min(0.2, Math.max(0.09, C));  // primary chroma
    const cs = 0.045, ct = 0.09, cn = 0.012, cnv = 0.02;
    const ht = (h + 60) % 360;
    const T = (L, c, hue) => tone(L, c, hue);

    const R = dark
      ? {
          primary: T(0.8, cp, h), onPrimary: T(0.3, cp, h),
          primaryContainer: T(0.4, cp, h), onPrimaryContainer: T(0.92, cs * 2, h),
          secondary: T(0.8, cs, h), onSecondary: T(0.3, cs, h),
          secondaryContainer: T(0.38, cs, h), onSecondaryContainer: T(0.9, cs, h),
          tertiary: T(0.82, ct, ht), onTertiary: T(0.3, ct, ht),
          tertiaryContainer: T(0.4, ct, ht), onTertiaryContainer: T(0.92, ct, ht),
          surfaceDim: T(0.145, cn, h), surface: T(0.17, cn, h),
          surfaceContainerLowest: T(0.13, cn, h), surfaceContainerLow: T(0.2, cn, h),
          surfaceContainer: T(0.225, cn, h), surfaceContainerHigh: T(0.26, cn, h),
          surfaceContainerHighest: T(0.295, cn, h),
          onSurface: T(0.93, cn, h), onSurfaceVariant: T(0.81, cnv, h),
          outline: T(0.65, cnv, h), outlineVariant: T(0.42, cnv, h),
          error: T(0.82, 0.12, 25), onError: T(0.3, 0.12, 25),
        }
      : {
          primary: T(0.5, cp, h), onPrimary: T(1, 0, h),
          primaryContainer: T(0.9, cp * 0.55, h), onPrimaryContainer: T(0.3, cp, h),
          secondary: T(0.5, cs, h), onSecondary: T(1, 0, h),
          secondaryContainer: T(0.91, cs, h), onSecondaryContainer: T(0.3, cs, h),
          tertiary: T(0.5, ct, ht), onTertiary: T(1, 0, ht),
          tertiaryContainer: T(0.91, ct, ht), onTertiaryContainer: T(0.3, ct, ht),
          surfaceDim: T(0.9, cn, h), surface: T(0.985, cn, h),
          surfaceContainerLowest: T(1, 0, h), surfaceContainerLow: T(0.965, cn, h),
          surfaceContainer: T(0.945, cn, h), surfaceContainerHigh: T(0.925, cn, h),
          surfaceContainerHighest: T(0.905, cn, h),
          onSurface: T(0.22, cn, h), onSurfaceVariant: T(0.42, cnv, h),
          outline: T(0.55, cnv, h), outlineVariant: T(0.82, cnv, h),
          error: T(0.5, 0.18, 25), onError: T(1, 0, 25),
        };
    return Object.fromEntries(Object.entries(R).map(([k, v]) => [k, hex(v)]));
  }

  /* ---------- apply: --md-* roles + Spotify's --spice-* variables ---------- */
  const kebab = (s) => s.replace(/[A-Z]/g, (m) => "-" + m.toLowerCase());
  const rgbStr = (h) => {
    const n = parseInt(h.slice(1), 16);
    return `${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}`;
  };

  // Detect light/dark from the active color_scheme in color.ini (read once)
  const mainRaw = getComputedStyle(root).getPropertyValue("--spice-main").trim().replace("#", "");
  let dark = true;
  if (/^[0-9a-f]{6}$/i.test(mainRaw)) {
    const n = parseInt(mainRaw, 16);
    dark = 0.2126 * ((n >> 16) & 255) + 0.7152 * ((n >> 8) & 255) + 0.0722 * (n & 255) < 128;
  }

  let registered = false;
  function registerOnce(names) {
    if (registered || !window.CSS?.registerProperty) return;
    registered = true;
    names.forEach((name) => {
      try { CSS.registerProperty({ name, syntax: "<color>", inherits: true, initialValue: "#000000" }); } catch (e) {}
    });
    root.style.transition = names.map((n) => `${n} 700ms cubic-bezier(.2,0,0,1)`).join(",");
  }

  function apply(seed) {
    const s = scheme(seed, dark);
    const vars = {};
    for (const [k, v] of Object.entries(s)) vars["--md-" + kebab(k)] = v;

    const map = {
      main: s.surfaceDim, sidebar: s.surfaceDim, player: s.surfaceContainer,
      "main-elevated": s.surfaceContainerHigh, card: s.surfaceContainer,
      highlight: s.surfaceContainerHigh, "highlight-elevated": s.surfaceContainerHighest,
      text: s.onSurface, subtext: s.onSurfaceVariant, "selected-row": s.onSurface,
      button: s.primary, "button-active": s.primary, "button-disabled": s.outlineVariant,
      "tab-active": s.secondaryContainer, notification: s.surfaceContainerHighest,
      "notification-error": s.error, equalizer: s.primary, misc: s.outlineVariant,
    };
    for (const [k, v] of Object.entries(map)) {
      vars["--spice-" + k] = v;
      root.style.setProperty("--spice-rgb-" + k, rgbStr(v)); // plain rgb triplet, not animated
    }

    registerOnce(Object.keys(vars));
    for (const [k, v] of Object.entries(vars)) root.style.setProperty(k, v);
  }

  async function update() {
    const item = Spicetify.Player.data?.item;
    if (!item) return;
    try {
      const c = await Spicetify.colorExtractor(item.uri);
      const seed = c.VIBRANT || c.PROMINENT || c.LIGHT_VIBRANT || c.DARK_VIBRANT;
      if (seed) apply(seed);
    } catch (e) { /* local file / no art: keep current palette */ }
  }

  Spicetify.Player.addEventListener("songchange", update);
  update();

  /* ---------- M3 ripple on pressable things ---------- */
  const PRESSABLE = [
    '[data-encore-id="buttonPrimary"]', '[data-encore-id="buttonSecondary"]',
    '[data-encore-id="buttonTertiary"]', '[data-encore-id="chip"]',
    ".main-playPauseButton-button", ".main-playButton-PlayButton",
    ".main-card-card", ".main-trackList-trackListRow", ".main-shortcuts-shortcut",
    ".main-yourLibraryX-listItem", ".link-subtle.main-navBar-navBarLink",
  ].join(",");

  document.addEventListener(
    "pointerdown",
    (e) => {
      const el = e.target.closest?.(PRESSABLE);
      if (!el || e.button !== 0) return;
      const r = el.getBoundingClientRect();
      const size = Math.max(r.width, r.height) * 2;
      const dot = document.createElement("span");
      dot.className = "md-ripple";
      dot.style.cssText = `width:${size}px;height:${size}px;left:${e.clientX - r.left - size / 2}px;top:${e.clientY - r.top - size / 2}px`;
      el.classList.add("md-ripple-host");
      el.appendChild(dot);
      dot.addEventListener("animationend", () => dot.remove());
    },
    true
  );
})();
