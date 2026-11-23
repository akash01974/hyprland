# Monet — Material You for Spicetify

Material 3 look with dynamic color: a full tonal palette (primary, secondary,
tertiary, surface containers, outline…) is generated from the current cover art
and crossfades on every track change. Includes M3 shapes, state layers,
pill nav indicators, FAB-style play buttons, and click ripples.

## Install
1. `spicetify path userdata` → open `Themes/`
2. Copy the `Monet` folder in.
3. Run:

```
spicetify config current_theme Monet color_scheme Dark
spicetify config inject_css 1 replace_colors 1 overwrite_assets 1 inject_theme_js 1
spicetify apply
```

## Light mode
`spicetify config color_scheme Light && spicetify apply`
(the theme detects light vs dark from the scheme and generates a matching palette)

## Tweaking
Shape radii, gaps and elevation are variables at the top of `user.css`
(`--md-shape-*`, `--md-gap`, `--md-elev-*`). To lock a fixed palette instead of
dynamic color, delete `theme.js`; the `color.ini` scheme will be used.

If a surface looks off after a Spotify update, a class name changed. Run
`spicetify enable-devtools`, press Ctrl+Shift+I, and update the selector.
