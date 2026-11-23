// Frostglass – immersive backdrop + dynamic accent from the current cover art
(function Frostglass() {
  if (!(Spicetify?.Player && Spicetify?.colorExtractor)) {
    setTimeout(Frostglass, 300);
    return;
  }

  const root = document.documentElement;

  // Two stacked layers so covers crossfade instead of popping
  const bg = document.createElement("div");
  bg.id = "fg-backdrop";
  bg.innerHTML = '<div class="fg-layer"></div><div class="fg-layer"></div><div class="fg-grain"></div>';
  document.body.prepend(bg);
  const layers = bg.querySelectorAll(".fg-layer");
  let active = 0;

  const toHttp = (uri) =>
    uri && uri.startsWith("spotify:image:")
      ? "https://i.scdn.co/image/" + uri.slice("spotify:image:".length)
      : uri;

  const hexToRgb = (hex, fallback = "185, 166, 255") => {
    if (!hex) return fallback;
    const h = hex.replace("#", "");
    if (h.length !== 3 && h.length !== 6) return fallback;
    const n = parseInt(h.length === 3 ? h.replace(/./g, "$&$&") : h, 16);
    if (isNaN(n)) return fallback;
    return `${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}`;
  };

  // Extract vibrant palette colors directly from the cover art image via offscreen canvas
  function extractColorsFromImage(imgUrl) {
    return new Promise((resolve) => {
      if (!imgUrl) return resolve(null);
      const img = new Image();
      img.crossOrigin = "Anonymous";
      img.onload = () => {
        try {
          const canvas = document.createElement("canvas");
          const ctx = canvas.getContext("2d");
          const w = 32, h = 32;
          canvas.width = w;
          canvas.height = h;
          ctx.drawImage(img, 0, 0, w, h);
          const data = ctx.getImageData(0, 0, w, h).data;

          const pixels = [];
          for (let i = 0; i < data.length; i += 16) {
            const r = data[i], g = data[i + 1], b = data[i + 2], a = data[i + 3];
            if (a < 128) continue;
            const max = Math.max(r, g, b), min = Math.min(r, g, b);
            const sat = max === 0 ? 0 : (max - min) / max;
            const lum = 0.299 * r + 0.587 * g + 0.114 * b;
            // Ignore pure black or blown-out white
            if (lum > 20 && lum < 240) {
              pixels.push({ r, g, b, sat, lum, score: sat * 3 + (lum / 255) });
            }
          }

          if (pixels.length === 0) return resolve(null);

          // Sort by vibrancy score
          pixels.sort((a, b) => b.score - a.score);

          const p1 = pixels[0];
          // Find second distinct color
          let p2 = pixels.find(p => (Math.abs(p.r - p1.r) + Math.abs(p.g - p1.g) + Math.abs(p.b - p1.b)) > 60)
                  || pixels[Math.min(4, pixels.length - 1)];
          // Find third deeper color
          let p3 = pixels.find(p => p.lum < p1.lum && (Math.abs(p.r - p1.r) + Math.abs(p.b - p1.b)) > 50)
                  || pixels[pixels.length - 1];

          resolve({
            col1: `${p1.r}, ${p1.g}, ${p1.b}`,
            col2: `${p2.r}, ${p2.g}, ${p2.b}`,
            col3: `${p3.r}, ${p3.g}, ${p3.b}`
          });
        } catch (e) {
          resolve(null);
        }
      };
      img.onerror = () => resolve(null);
      img.src = imgUrl;
    });
  }

  function findColor(c, ...keys) {
    if (!c) return null;
    if (typeof c === "string") return c;
    for (const key of keys) {
      for (const k of Object.keys(c)) {
        if (k.toLowerCase().replace(/_/g, "") === key.toLowerCase().replace(/_/g, "")) {
          const val = c[k];
          if (typeof val === "string" && val.startsWith("#")) return val;
        }
      }
    }
    return null;
  }

  async function update() {
    const item = Spicetify.Player.data?.item;
    if (!item) return;

    const img = toHttp(item.metadata?.image_xlarge_url || item.metadata?.image_url);
    if (img) {
      const next = layers[1 - active];
      next.style.backgroundImage = `url("${img}")`;
      next.classList.add("on");
      layers[active].classList.remove("on");
      active = 1 - active;
      root.style.setProperty("--fg-cover", `url("${img}")`);
    }

    let c1 = null, c2 = null, c3 = null;

    if (item.uri && Spicetify.colorExtractor) {
      try {
        const c = await Spicetify.colorExtractor(item.uri);
        const v = findColor(c, "VIBRANT", "vibrant");
        const lv = findColor(c, "LIGHT_VIBRANT", "lightvibrant", "light_vibrant");
        const p = findColor(c, "PROMINENT", "prominent");
        const dv = findColor(c, "DARK_VIBRANT", "darkvibrant", "dark_vibrant");
        const des = findColor(c, "DESATURATED", "desaturated", "muted");

        if (v || p || lv) c1 = hexToRgb(v || p || lv);
        if (lv || p || v) c2 = hexToRgb(lv || p || v);
        if (dv || des || v) c3 = hexToRgb(dv || des || v);
      } catch (e) {
        /* fallback to canvas extractor */
      }
    }

    // Canvas extraction from cover image: extracts authentic 3-color palette directly from artwork
    if (img) {
      try {
        const palette = await extractColorsFromImage(img);
        if (palette) {
          if (!c1) c1 = palette.col1;
          if (!c2 || c2 === c1) c2 = palette.col2;
          if (!c3 || c3 === c1) c3 = palette.col3;
        }
      } catch (e) {
        /* ignore */
      }
    }

    if (c1) {
      root.style.setProperty("--fg-accent", `rgb(${c1})`);
      root.style.setProperty("--fg-accent-rgb", c1);
      root.style.setProperty("--fg-accent-1-rgb", c1);
    }
    if (c2) {
      root.style.setProperty("--fg-accent-2-rgb", c2);
    } else if (c1) {
      root.style.setProperty("--fg-accent-2-rgb", c1);
    }
    if (c3) {
      root.style.setProperty("--fg-deep-rgb", c3);
      root.style.setProperty("--fg-accent-3-rgb", c3);
    } else if (c1) {
      root.style.setProperty("--fg-deep-rgb", c1);
      root.style.setProperty("--fg-accent-3-rgb", c1);
    }
  }

  Spicetify.Player.addEventListener("songchange", () => setTimeout(update, 200));
  
  // Retry update in case player data isn't ready on startup
  let retries = 0;
  function tryUpdate() {
    if (Spicetify.Player.data?.item) {
      update();
    } else if (retries < 15) {
      retries++;
      setTimeout(tryUpdate, 400);
    }
  }
  tryUpdate();

  // Watch scroll on main view to toggle .fg-scrolled on topbar
  function initScrollWatcher() {
    let ticking = false;

    function check(e) {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(() => {
        ticking = false;
        const topBar = document.querySelector(".main-topBar-container");
        if (!topBar) return;
        const target = e?.target;
        const scrollTop = (target && typeof target.scrollTop === "number")
          ? target.scrollTop
          : (document.querySelector(".os-viewport")?.scrollTop || 0);

        if (scrollTop > 15) {
          topBar.classList.add("fg-scrolled");
        } else {
          topBar.classList.remove("fg-scrolled");
        }
      });
    }

    // Capture-phase listener efficiently intercepts scroll events without DOM mutation overhead
    window.addEventListener("scroll", check, { passive: true, capture: true });
    check();
  }

  initScrollWatcher();
})();
