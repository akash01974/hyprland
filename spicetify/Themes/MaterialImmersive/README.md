# Material Immersive (Spicetify)

Material 3 theme: album-art-derived tonal palette, blurred full-bleed backdrop, floating glass panes, FAB-style play buttons, state layers and ripples.

## Install
1. Copy this folder to your Spicetify themes dir (`spicetify path userdata` → `Themes/MaterialImmersive`).
2. Run:
   ```bash
   spicetify config current_theme MaterialImmersive color_scheme Dark
   spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
   spicetify apply
   ```

Use `color_scheme Light` for the light variant.

## Tweak
- Backdrop strength: `--md-pane-alpha` in user.css (lower = more art shows through).
- Corner shape: `--md-r-*` tokens.
