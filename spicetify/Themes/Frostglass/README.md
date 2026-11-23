<div align="center">

# Frostglass

An adaptive frosted-glass theme for Spotify powered by [Spicetify](https://spicetify.app).

[![Spicetify](https://img.shields.io/badge/Spicetify-v2.x-1db954?style=flat-square&logo=spotify&logoColor=white)](https://spicetify.app)
[![CSS3](https://img.shields.io/badge/CSS-Glassmorphic-264de4?style=flat-square&logo=css3&logoColor=white)](https://www.w3.org/Style/CSS/)
[![JavaScript](https://img.shields.io/badge/JavaScript-ES6+-f7df1e?style=flat-square&logo=javascript&logoColor=black)](https://developer.mozilla.org/en-US/docs/Web/JavaScript)

</div>

---

Frostglass transforms Spotify into a fluid, translucent glassmorphic interface. The current track's album artwork is rendered as a dual-layer blurred, slowly drifting background, while a built-in reactive script extracts dominant color palettes to dynamically illuminate controls, progress bars, and glowing glass accents.

## Features

- **Adaptive Ambient Canvas**: Renders high-resolution album artwork into an organic, drifting dual-layer backdrop with crossfades between track transitions.
- **Real-Time Palette Extraction**: Dynamically samples `VIBRANT`, `LIGHT_VIBRANT`, and `PROMINENT` tones using `Spicetify.colorExtractor` to tint UI elements, glows, and gradients live.
- **Floating Island Player Bar**: A detached glass capsule with an animated shifting gradient, ambient backlight halo, and cover-art light bleed.
- **Kinetic Progress & Volume Bars**:
  - Continuous linear shimmer sweep across active fill layers.
  - Ambient breathing pulse synchronized to the track accent color.
  - Interactive scrubber thumb with tactile hover scaling and bloom glow.
- **Refined Glass Interface**:
  - Translucent pill filter chips (`All`, `Music`, `Podcasts`) with accent-highlighted active states.
  - Frosted circular navigation and history buttons with subtle top-edge lighting.
  - Full removal of intrusive legacy header gradients.
- **Native Marketplace Integration**: Seamless styling for the Spicetify Marketplace custom app, featuring glass category tabs, transparent search headers, and frosted modal dialogs.
- **Performance & Accessibility**: Respects `prefers-reduced-motion` and `prefers-reduced-transparency` media queries.

---

## Prerequisites

- [Spotify Desktop](https://www.spotify.com/download/) (Linux, macOS, or Windows)
- [Spicetify CLI](https://spicetify.app/docs/getting-started) (v2.x or later)

---

## Installation

### Linux / macOS

1. Open your terminal and ensure your Spicetify `Themes` directory exists:
   ```bash
   mkdir -p "$(spicetify -c | xargs dirname)/Themes"
   cd "$(spicetify -c | xargs dirname)/Themes"
   ```

2. Clone this repository into `Themes/Frostglass`:
   ```bash
   git clone https://github.com/<owner>/Frostglass.git Frostglass
   ```
   *(Alternatively, copy the `Frostglass` directory manually into `~/.config/spicetify/Themes/`)*

3. Configure Spicetify and apply the theme:
   ```bash
   spicetify config current_theme Frostglass color_scheme Dusk
   spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
   spicetify apply
   ```

---

### Windows (PowerShell)

1. Open PowerShell and navigate to your Spicetify `Themes` directory:
   ```powershell
   $themesPath = Join-Path (Split-Path (spicetify -c)) "Themes"
   if (!(Test-Path $themesPath)) { New-Item -ItemType Directory -Path $themesPath -Force }
   Set-Location $themesPath
   ```

2. Clone this repository into `Themes\Frostglass`:
   ```powershell
   git clone https://github.com/<owner>/Frostglass.git Frostglass
   ```
   *(Alternatively, extract the ZIP into `%userprofile%\.spicetify\Themes\Frostglass` or `%appdata%\spicetify\Themes\Frostglass`)*

3. Configure Spicetify and apply the theme:
   ```powershell
   spicetify config current_theme Frostglass color_scheme Dusk
   spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
   spicetify apply
   ```

> [!TIP]
> If Spotify is already running, press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> (or <kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd> on macOS) to reload and mount the theme immediately.

---

## Color Schemes

Frostglass includes three curated baseline color palettes in `color.ini`. While the dynamic extraction engine tints interactive elements based on album artwork, the base palette determines baseline text contrast, surface tones, and neutral borders:

| Scheme | Accent Default | Palette Description | Switch Command |
|---|---|---|---|
| `Dusk` | `#b9a6ff` | Deep midnight violet & sleek dark glass | `spicetify config color_scheme Dusk && spicetify apply` |
| `Ember` | `#ff9a5c` | Warm obsidian & fiery ambient tones | `spicetify config color_scheme Ember && spicetify apply` |
| `Tide` | `#5ce1e6` | Deep marine cyan & cool glass surfaces | `spicetify config color_scheme Tide && spicetify apply` |

> [!NOTE]
> The selected color scheme establishes the foundation before playback begins. During playback, CSS variables `--fg-accent`, `--fg-accent-rgb`, and `--fg-cover` dynamically update to reflect the playing track.

---

## Configuration

Fine-tune glass density, blur radius, and layout spacing by editing the CSS custom properties at the top of [`user.css`](user.css):

| Variable | Default Value | Description |
|---|---|---|
| `--fg-blur` | `blur(42px) saturate(190%)` | Backdrop blur and saturation intensity |
| `--fg-glass` | `rgba(255, 255, 255, 0.06)` | Baseline glass fill opacity for panels and cards |
| `--fg-glass-strong` | `rgba(255, 255, 255, 0.10)` | Elevated opacity for buttons, inputs, and active chips |
| `--fg-glass-hover` | `rgba(255, 255, 255, 0.14)` | Interactive hover state brightness |
| `--fg-edge` | `rgba(255, 255, 255, 0.10)` | Border rim outline opacity |
| `--fg-edge-top` | `rgba(255, 255, 255, 0.22)` | Top-edge specular highlight reflection |
| `--fg-radius` | `22px` | Corner radius for major panes and now-playing island |
| `--fg-radius-sm` | `14px` | Corner radius for cards, dropdowns, and modal controls |
| `--fg-gap` | `12px` | Grid spacing and outer margin padding between panels |

Run `spicetify apply` whenever you modify these properties.

---

## Troubleshooting

### Changes Not Visible

If applying changes does not immediately reflect in Spotify:

```bash
spicetify apply
```

Then hard-reload the client UI with <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>R</kbd>.

### Inspecting UI Elements

Spotify desktop updates occasionally adjust internal class names or DOM structure. To debug or inspect selectors:

1. Enable Spotify developer tools:
   ```bash
   spicetify enable-devtools
   ```
2. Restart Spotify and press <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>I</kbd> to open DevTools.
3. Target any newly obfuscated containers and add their class names to the transparency rules in `user.css`.

> [!IMPORTANT]
> When updating Spicetify or Spotify, always execute `spicetify backup apply` or `spicetify upgrade` to maintain binary injection compatibility.
