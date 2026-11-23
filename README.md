# omarchy-vlc

VLC media player, working properly on [Omarchy](https://omarchy.org).

Out of the box, the VLC that Arch packages has four problems on Omarchy:

- **It can't be moved.** Hyprland tiles it and draws no title bars, so there is
  nothing to grab, and no way to drag it to another monitor.
- **It doesn't play H.264.** Arch splits VLC into plugin packages, and the
  FFmpeg one (H.264, HEVC, MPEG-4, AAC) isn't installed with it.
- **Dropping a file on it opens the wrong thing.** VLC 3 runs through XWayland,
  and when you drop a file from Nautilus on an XWayland window, Hyprland
  (0.56.2) hands the window whatever is on your clipboard instead of the file.
- **It resizes itself** to every video's own size, so a 4K file opens a window
  bigger than the screen.

This sets up the VLC you already have. It is not a separate build of VLC:

- **Every VLC window floats and has a title bar.** Drag the bar to move the
  window, also onto another monitor. Double-click it to maximize. It has
  minimize, maximize and close buttons, and follows your Omarchy theme. The
  bars come from Omarchy's own title bar plugin, the one its floating
  workspaces use.
- **The player opens centered**, 60% of the monitor's width at 16:9, so it fits
  portrait monitors too.
- **H.264 and the rest play**, with hardware decoding (VDPAU or VA-API).
- **Dropped files open.** Drop one or several on any VLC window. If something
  is playing they queue up behind it; otherwise the first one starts.
- **The window keeps the size you give it** when a video starts.
- **The screen stays awake** while a video plays fullscreen.
- **Omarchy VLC** is in the app launcher (Super+Space), in place of the stock
  "VLC media player" entry. Files that open in VLC still do.

It is made for Omarchy and for the
[Neko Legends Control Center](https://github.com/neko-legends/neko-legends-control-center).

## Install

Get it from the Neko Legends Control Center, which downloads
`omarchy-vlc-linux-x86_64.zip` from the latest
[release](https://github.com/neko-legends/omarchy-vlc/releases) and runs
`omarchy-vlc-portable` from wherever it unpacks it. The first start sets
everything up and asks for your password once, to install `vlc`,
`vlc-plugin-ffmpeg` and `vlc-plugin-dbus` if they are missing.

Or from a clone:

```sh
bin/install
```

Either way it changes these, and nothing else:

| What | Where |
| --- | --- |
| Packages, if missing | `vlc`, `vlc-plugin-ffmpeg`, `vlc-plugin-dbus`, `omarchy-hyprland-titlebars` |
| Window rules | `~/.config/hypr/vlc.lua`, loaded by one `require("hypr.vlc")` line added to `~/.config/hypr/hyprland.lua` (backed up first) |
| Drop helper | `~/.local/share/omarchy-vlc/omarchy-vlc-dnd` |
| Launcher entry | `~/.local/share/applications/vlc.desktop` |
| VLC setting | `qt-video-autoresize=0` in `~/.config/vlc/vlcrc` (backed up first) |

Running it again changes only what is missing or out of date.

## Using it

- **Drag the title bar**: move VLC, also onto another monitor
- **Drop files on VLC**: they play, or queue up if something is playing
- **Double-click the title bar**: maximize
- **SUPER + left mouse drag**: move VLC by grabbing it anywhere
- **SUPER + right mouse drag**: resize
- **SUPER + SHIFT + CTRL + arrow**: send the window to the monitor in that direction
- **SUPER + T**: tile it
- **F**, or double-click the video: fullscreen on the monitor VLC is on

## Uninstall

```sh
bin/uninstall
```

This removes the window rules, the drop helper and the launcher entry, and the
stock "VLC media player" entry returns. VLC and its codec plugin stay installed.

## How it works

| File | What it does |
| --- | --- |
| `hypr/vlc.lua` | Hyprland rules: float, size and center the player, keep the screen awake in fullscreen, load `omarchy-hyprland-titlebars` with a tag on VLC's windows so they get title bars, and start the drop helper when a VLC window opens |
| `omarchy-vlc-dnd` | The drop helper. Registers as the drop proxy (`XdndProxy`) of every VLC window, reads the dragged files while the drag still hovers, and on the drop hands them to VLC over D-Bus (MPRIS). Python and libxcb, nothing else |
| `vlc.desktop` | The "Omarchy VLC" launcher entry. Same id as the stock entry, so it replaces it |
| `bin/install` | Installs the packages, the rules, the drop helper, the launcher entry and the VLC setting |
| `bin/uninstall` | Takes the rules, the drop helper and the launcher entry out again |
| `omarchy-vlc-portable` | What the Control Center runs: `bin/install`, then VLC |

### Why drops need a helper

When a drag from a Wayland app enters an XWayland window, Hyprland offers the
window the drag's data. At the drop, keyboard focus lands on the window, and
Hyprland sends it the clipboard as it does on every focus change. That replaces
the drag's offer, because the X11 side keeps both in one list. VLC, like every
Qt app, asks for the data after the drop, so it gets the clipboard. With a file
path on the clipboard VLC opens that path; with anything else the drop does
nothing.

The helper asks for the data on enter, while the drag's offer is still the one
Hyprland serves. Dragging inside VLC, such as reordering the playlist, never
leaves VLC and does not go through the helper. One thing is lost: a subtitle
file dropped on a playing video is queued as a file instead of being added as
subtitles (use Subtitle > Add Subtitle File).

Its log is `~/.cache/omarchy-vlc-dnd.log`.

Pushing a `v*` tag attaches the zip to that tag's release
(`.github/workflows/release.yml`).

## License

MIT. See `LICENSE`. VLC itself is not included; it is installed from the Arch
repositories under its own license (GPL-2.0-or-later).
