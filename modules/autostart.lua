--[[ AUTOSTART ]]

hl.on("hyprland.start", function()

    -- Enable NumLock FIRST
    hl.exec_cmd("numlockx on")

    -- Then start lock screen (if needed)
    hl.exec_cmd("hyprlock")

    -- Clipboard persistence & history
    hl.exec_cmd("wl-clip-persist --clipboard regular")
    hl.exec_cmd("wl-paste --watch cliphist store")

    -- Other services
    hl.exec_cmd("swaync")
    hl.exec_cmd("waybar")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("nautilus --gapplication-service")

end)