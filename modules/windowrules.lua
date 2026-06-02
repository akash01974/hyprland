--[[ WINDOW RULES ]]

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})

hl.layer_rule({
    name = "rofi-dropdown",
    match = { namespace = "rofi" },
    animation = "slide bottom",
    dim_around = true,
    blur = true,
    ignore_alpha = 0.2,
})

hl.layer_rule({
    name = "notification-animations",
    match = { namespace = "swaync-control-center" },
    animation = "slide right",
    blur = true,
    ignore_alpha = 0.5,
})

hl.layer_rule({
    name = "notification-popup-blur",
    match = { namespace = "swaync-notification" },
    blur = true,
    ignore_alpha = 0.5,
})

hl.window_rule({
    name = "vscode-blur",
    match = { class = "code" },
    opacity = 0.85,
})

hl.window_rule({
    name = "antigravity-ide-blur",
    match = { class = "antigravity-ide" },
    opacity = 0.85,
})

hl.window_rule({
    name = "kitty-blur",
    match = { class = "kitty" },
    opacity = 0.7,
})