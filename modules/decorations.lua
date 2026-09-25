--[[ DECORATIONS ]]

local colors = require("colors")

hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 10,

        border_size      = 1,

        col              = {
            active_border   = colors.active_border,
            inactive_border = colors.inactive_border,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing    = false,
    },
})

hl.config({
    decoration = {
        rounding         = 20,
        rounding_power   = 10,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow           = {
            enabled        = true,
            range          = 15,
            render_power   = 3,
            color          = 0xa0000000,
            color_inactive = 0x00000000,
        },

        blur             = {
            enabled  = true,
            size     = 7,
            passes   = 3,
            vibrancy = 0.1696,
        },
    },
})

-- Smooth bezier curves
hl.curve("smoothOut", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1 } } })
hl.curve("smoothInOut", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("gentle", { type = "bezier", points = { { 0.2, 0.8 }, { 0.2, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("mybezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

-- Soft spring with higher damping for fluid, non-jittery motion
hl.curve("softBounce", { type = "spring", mass = 0.8, stiffness = 490, dampening = 32 })

hl.animation({ leaf = "global", enabled = true, speed = 6, bezier = "smoothOut" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "smoothInOut" })
hl.animation({ leaf = "windows", enabled = true, speed = 4, spring = "softBounce" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5, spring = "softBounce", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "smoothOut", style = "popin 80%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.5, bezier = "gentle" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "gentle" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "smoothInOut" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.5, bezier = "smoothOut" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "smoothOut", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "gentle", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.5, bezier = "gentle" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2, bezier = "gentle" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "smoothInOut", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 2.5, bezier = "smoothOut", style = "slidefade 20%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.5, bezier = "smoothOut", style = "slidefade 20%" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 5, bezier = "smoothInOut" })
