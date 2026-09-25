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
    name = "pill-base",
    match = { namespace = "pill" },
    no_anim = true,
    ignore_alpha = 0.5,
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
    name = "wlogout-blur",
    match = { namespace = "wlogout" },
    blur = true,
    ignore_alpha = 0.2,
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

hl.window_rule({
    name = "spotify-blur",
    match = { class = "Spotify" },
    opacity = 0.75,
})

hl.window_rule({
    name = "thunar-appearance",
    match = { class = "Thunar" },
    rounding = 16,
})

hl.window_rule({
    name = "thunar-opacity",
    match = { class = "Thunar" },
    opacity = 0.95,
})

-- window focus handled by misc.focus_on_activate

-- Stash / Private / Minimized: auto-route configured apps to special workspaces
local lists = {
    stash     = "modules.stash-apps",
    private   = "modules.private-apps",
    minimized = "modules.minimized-apps",
}
for wsName, modName in pairs(lists) do
    local ok, apps = pcall(require, modName)
    if ok and type(apps) == "table" then
        for _, cls in ipairs(apps) do
            hl.window_rule({
                name      = wsName .. "-" .. cls,
                match     = { class = cls },
                workspace = "special:" .. wsName,
            })
        end
    end
end