# AlbumAmbient

A Spicetify theme that recolours Spotify's desktop client from the current track's cover art. One ambient gradient is painted behind the whole app, panels are translucent over it, and the palette crossfades on every track change.

## Install

1. Install [Spicetify](https://spicetify.app) and apply it to Spotify once.
2. Copy this folder to your Spicetify themes directory:
   - Windows: `%appdata%\spicetify\Themes\AlbumAmbient`
   - macOS / Linux: `~/.config/spicetify/Themes/AlbumAmbient`
3. Run:

```
spicetify config current_theme AlbumAmbient color_scheme base
spicetify config inject_css 1 inject_theme_js 1 replace_colors 1 overwrite_assets 1
spicetify apply
```

To remove it: `spicetify config current_theme " "` then `spicetify apply`.

## How it works

| File | Role |
|---|---|
| `theme.js` | Reads the cover URL from `Spicetify.Player.data`, downsamples it to 48x48 on a canvas, picks a dominant and a distinct secondary hue, clamps saturation and lightness, and checks contrast. Writes `--album-primary`, `--album-secondary`, `--album-accent`, `--album-background` on `<html>`. Nothing else. |
| `user.css` | Registers those variables with `@property` so they animate, builds `--ambient-gradient` and surface tokens, overrides Spotify's Encore tokens (`--background-*`, `--text-*`), and neutralises hard-coded page-header colours. |
| `color.ini` | Dark fallback scheme for Spicetify. |
| `palette.test.js` | `node palette.test.js` runs the extractor on synthetic dark, bright, warm, cool, neon, monochrome, greyscale and white covers. |

Guarantees enforced in code: white text on primary/secondary is at least 6:1, accent on background is at least 7:1, background lightness is about 6%, saturation is capped near 0.6. Missing or local-file artwork falls back to a deep indigo default.

Performance: no blur on large containers (only a 12px blur on context menus), no repeated background image, and the gradient only repaints for about 1.1s after a track change.

## Known limits

- Requires a Spotify build with Chromium 111+ (`color-mix()`, `@property`).
- Spotify renames internal classes between releases. Colours mostly flow through the Encore variables, which are stable, but the per-class rules (page headers, top bar, lyrics, modals) may need updating. Open DevTools (`spicetify enable-devtools`, then Ctrl+Shift+I) and adjust the selectors in sections 5 and 6 of `user.css`.
- Search category tiles keep their own colours.
