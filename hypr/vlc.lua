-- omarchy-vlc: make VLC behave like a native Omarchy app under Hyprland.
-- Installed by bin/install as ~/.config/hypr/vlc.lua. https://github.com/neko-legends/omarchy-vlc
--
-- VLC 3 is a Qt5/XWayland app with no title bar of its own. Tiled, it can't be
-- dragged around, and it resizes itself to each video's native size. So every
-- VLC window floats and gets a title bar to drag it by, also across monitors
-- (SUPER + left mouse drags it from anywhere, SUPER + right mouse resizes,
-- SUPER + T tiles it again).

-- All VLC windows (player, Preferences, Open Media, Media Info) float.
o.window("^(vlc)$", { float = true })

-- The main player window opens centered on the current monitor, 60% of its width
-- at 16:9 (plus room for VLC's menu and controls), so it fits portrait monitors too.
o.window({ class = "^(vlc)$", title = "VLC media player$" }, { center = true })
o.window({ class = "^(vlc)$", title = "VLC media player$" }, { size = { "(monitor_w*0.6)", "(monitor_w*0.6*0.5625+90)" } })

-- Keep the screen awake while a video plays fullscreen.
o.window("^(vlc)$", { idle_inhibit = "fullscreen" })

-- Title bars -----------------------------------------------------------------
-- VLC draws no title bar under Hyprland, so there is nothing to grab with a
-- plain mouse drag. Omarchy ships a title bar plugin (omarchy-hyprland-titlebars)
-- for its floating workspaces; it draws a bar on every window that carries the
-- tag below. VLC windows get that tag, so they can be dragged by the bar, also
-- across monitors, and closed/maximized/minimized with its buttons.

local TITLEBARS = "/usr/lib/omarchy-hyprland-titlebars/titlebars.so"
local TAG = "omarchy-floating-workspace"

local function exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
  end
  return file ~= nil
end

-- Same colors Omarchy's floating workspaces use, from the current theme.
local function theme_colors()
  local colors = {}
  local file = io.open((os.getenv("HOME") or "") .. "/.local/state/omarchy/current/theme/colors.toml", "r")

  if file then
    for line in file:lines() do
      local key, value = line:match('^%s*([%w_]+)%s*=%s*"#(%x%x%x%x%x%x)"')
      if key then
        colors[key] = "rgb(" .. value .. ")"
      end
    end
    file:close()
  end

  local background = colors.background or "rgb(1a1b26)"
  local titlebar = colors.lighter_background
  if not titlebar or titlebar == background then
    titlebar = colors.selection or background
  end

  return { foreground = colors.foreground or "rgb(c0caf5)", titlebar = titlebar }
end

local function titlebars()
  if not exists(TITLEBARS) then
    return false
  end

  -- The plugin reloads the config once it is in; that second pass finds
  -- hl.plugin.hyprbars and configures it.
  hl.plugin.load(TITLEBARS)
  if not hl.plugin.hyprbars then
    return false
  end

  -- A floating workspace (Appearance > Workspace Layout) has already set the
  -- bars up during this config load; setting them up twice doubles the buttons.
  local ok, enabled = pcall(hl.get_config, "plugin:hyprbars:enabled")
  if ok and (enabled == true or enabled == 1) then
    return true
  end

  local colors = theme_colors()
  local window = [[window = "address:%WINDOW%"]]
  local maximize = "hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = \"maximized\", action = \"toggle\", "
    .. window
    .. " })'"

  hl.config({
    plugin = {
      hyprbars = {
        enabled = true,
        workspace_tag = TAG,
        bar_height = 30,
        bar_color = colors.titlebar,
        col = { text = colors.foreground },
        bar_text_font = "monospace",
        bar_text_size = 12,
        bar_text_weight = "normal",
        bar_text_align = "left",
        bar_buttons_alignment = "right",
        bar_part_of_window = true,
        bar_precedence_over_border = true,
        bar_padding = 10,
        bar_button_padding = 8,
        button_rounding = 0,
        icon_on_hover = false,
        inactive_button_color = colors.titlebar,
        on_double_click = maximize,
      },
    },
  })

  for _, button in ipairs({
    { icon = "×", action = "hyprctl dispatch 'hl.dsp.window.close({ " .. window .. " })'" },
    { icon = "□", action = maximize },
    { icon = "−", action = "omarchy-hyprland-window-minimize %WINDOW%" },
  }) do
    hl.plugin.hyprbars.add_button({
      bg_color = colors.titlebar,
      fg_color = colors.foreground,
      size = 20,
      icon = button.icon,
      action = button.action,
    })
  end

  return true
end

if titlebars() then
  hl.window_rule({ match = { class = "^(vlc)$" }, tag = "+" .. TAG })
end

-- Dropping files ---------------------------------------------------------------
-- Hyprland hands an XWayland window the clipboard instead of the dragged file
-- when something is dropped on it from a Wayland app. omarchy-vlc-dnd takes
-- VLC's drops and passes the files on over D-Bus. It keeps running once
-- started, and a second copy exits at once, so starting it for every VLC
-- window is fine.
local DND = (os.getenv("HOME") or "") .. "/.local/share/omarchy-vlc/omarchy-vlc-dnd"

if exists(DND) then
  hl.on("window.open", function(window)
    if window and window.class == "vlc" then
      hl.exec_cmd(DND)
    end
  end)
end
