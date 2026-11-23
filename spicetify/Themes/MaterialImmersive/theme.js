// Material Immersive — dynamic Material 3 color + album-art backdrop
(function MaterialImmersive() {
  if (!window.Spicetify || !Spicetify.Player || !Spicetify.colorExtractor || !Spicetify.Player.data) {
    return setTimeout(MaterialImmersive, 300);
  }
  const root = document.documentElement;
  const clamp = (v, a, b) => Math.min(b, Math.max(a, v));

  const hexToHsl = (hex) => {
    hex = hex.trim().replace("#", "");
    const [r, g, b] = [0, 2, 4].map((i) => parseInt(hex.substr(i, 2), 16) / 255);
    const max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min, l = (max + min) / 2;
    let h = 0, s = 0;
    if (d) {
      s = d / (1 - Math.abs(2 * l - 1));
      h = max === r ? ((g - b) / d) % 6 : max === g ? (b - r) / d + 2 : (r - g) / d + 4;
      h = (h * 60 + 360) % 360;
    }
    return { h, s, l };
  };
  const hslToRgb = (h, s, l) => {
    const c = (1 - Math.abs(2 * l - 1)) * s, x = c * (1 - Math.abs(((h / 60) % 2) - 1)), m = l - c / 2;
    const [r, g, b] = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x]
      : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x];
    return [r, g, b].map((v) => Math.round((v + m) * 255));
  };
  const toHex = (rgb) => "#" + rgb.map((v) => v.toString(16).padStart(2, "0")).join("");

  // Respect the chosen color scheme (Dark / Light) from color.ini
  const base = getComputedStyle(root).getPropertyValue("--spice-main") || "#141218";
  const dark = hexToHsl(base).l < 0.5;
  const T = dark
    ? { p: 80, onp: 20, pc: 30, onpc: 90, sc: 30, onsc: 90, s: 8, c: 12, ch: 17, chh: 22, on: 90, onv: 78 }
    : { p: 40, onp: 100, pc: 90, onpc: 10, sc: 90, onsc: 10, s: 98, c: 94, ch: 92, chh: 90, on: 10, onv: 30 };

  function applyPalette(h, s) {
    const pS = clamp(s, 0.45, 0.95), nS = clamp(s * 0.25, 0.06, 0.2), nvS = clamp(s * 0.18, 0.04, 0.14);
    const P = (L) => hslToRgb(h, pS, L / 100);       // primary tonal
    const N = (L) => hslToRgb(h, nS, L / 100);       // neutral tonal
    const NV = (L) => hslToRgb(h, nvS, L / 100);     // neutral variant
    const S = (L) => hslToRgb(h, clamp(s * 0.3, 0.1, 0.3), L / 100); // secondary tonal

    const set = (k, rgb) => {
      root.style.setProperty(`--spice-${k}`, toHex(rgb));
      root.style.setProperty(`--spice-rgb-${k}`, rgb.join(","));
    };
    const md = (k, rgb, asRgb) => root.style.setProperty(`--md-${k}`, asRgb ? rgb.join(",") : toHex(rgb));

    const surface = N(T.s), cont = N(T.c), contHi = N(T.ch), contHiHi = N(T.chh);
    set("main", surface); set("sidebar", surface); set("player", cont);
    set("main-elevated", contHi); set("card", contHi);
    set("highlight", contHiHi); set("highlight-elevated", contHiHi);
    set("text", NV(T.on)); set("subtext", NV(T.onv)); set("selected-row", NV(T.on));
    set("button", P(T.p)); set("button-active", P(dark ? 88 : 30));
    set("tab-active", S(T.sc)); set("misc", NV(dark ? 60 : 50));

    md("primary", P(T.p)); md("on-primary", P(T.onp));
    md("primary-container", P(T.pc)); md("on-primary-container", P(T.onpc));
    md("secondary-container", S(T.sc)); md("on-secondary-container", S(T.onsc));
    md("surface-rgb", surface, true); md("container-rgb", cont, true);
    md("container-high-rgb", contHi, true); md("on-surface-rgb", NV(T.on), true);
  }

  // ── Backdrop with cross-fade between two layers ──────────────
  const backdrop = document.createElement("div");
  backdrop.id = "md-backdrop";
  backdrop.innerHTML = '<div class="layer"></div><div class="layer"></div>';
  document.body.prepend(backdrop);
  const layers = [...backdrop.children];
  let active = 0;

  function setBackdrop(url) {
    if (!url) return layers.forEach((l) => l.classList.remove("on"));
    const img = new Image();
    img.onload = () => {
      const next = layers[(active + 1) % 2], prev = layers[active];
      next.style.backgroundImage = `url("${url}")`;
      next.classList.add("on");
      prev.classList.remove("on");
      active = (active + 1) % 2;
    };
    img.src = url;
  }

  async function update() {
    const item = Spicetify.Player.data?.item;
    if (!item) return;
    const meta = item.metadata || {};
    const raw = meta.image_xlarge_url || meta.image_large_url || meta.image_url || "";
    setBackdrop(raw.replace("spotify:image:", "https://i.scdn.co/image/"));
    try {
      const c = await Spicetify.colorExtractor(item.uri);
      const pick = c.VIBRANT || c.PROMINENT || c.LIGHT_VIBRANT || c.DARK_VIBRANT;
      if (pick) { const { h, s } = hexToHsl(pick); applyPalette(h, s); }
    } catch (e) { /* keep previous palette */ }
  }

  Spicetify.Player.addEventListener("songchange", update);
  update();

  // ── Ripple on interactive surfaces ───────────────────────────
  document.addEventListener("pointerdown", (e) => {
    const el = e.target.closest(
      '.main-card-card, .main-trackList-trackListRow, .main-playButton-PlayButton, button[data-testid="play-button"], [data-testid="control-button-playpause"]'
    );
    if (!el) return;
    const r = el.getBoundingClientRect(), size = Math.max(r.width, r.height) * 2;
    const dot = document.createElement("span");
    dot.className = "md-ripple";
    dot.style.cssText = `width:${size}px;height:${size}px;left:${e.clientX - r.left - size / 2}px;top:${e.clientY - r.top - size / 2}px`;
    el.appendChild(dot);
    dot.addEventListener("animationend", () => dot.remove());
  }, { passive: true });
})();
