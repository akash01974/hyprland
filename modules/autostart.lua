--[[ AUTOSTART ]]

hl.on("hyprland.start", function()

    -- Lock screen immediately on boot — before anything else
    hl.exec_cmd("hyprlock")

    -- Enable NumLock
    hl.exec_cmd("numlockx on")

    -- Set cursor theme
    hl.exec_cmd("hyprctl setcursor Vision-Cursor-White 24")

    -- Kill old services replaced by Quickshell
    hl.exec_cmd("pkill waybar 2>/dev/null")

    -- Clipboard persistence & history
    hl.exec_cmd("wl-clip-persist --clipboard regular")
    hl.exec_cmd("wl-paste --watch cliphist store")

    -- Other services
    hl.exec_cmd("wifi-manager")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("thunar --daemon")

    -- Power profile change notifications
    hl.exec_cmd("~/.config/hypr/scripts/power-profile-monitor.sh")

    -- Initialize wallpaper from saved state (or pick random)
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/wallpaper.sh init")

    -- Quickshell daemons
    hl.exec_cmd("systemctl --user start hyprland-session.target")
    hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/pill-daemon.sh")
end)