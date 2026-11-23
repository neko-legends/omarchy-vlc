Omarchy VLC: VLC media player, working properly on Omarchy. It floats, has a
title bar to drag it across monitors, plays H.264, and opens the files you
drop on it.

Run ./omarchy-vlc-portable, or open it from the Neko Legends Control Center.
The first start sets things up and asks for your password once, to install VLC
and its FFmpeg and D-Bus plugins from the Arch repositories if they are missing.
After that "Omarchy VLC" is in the Omarchy app launcher (Super+Space) too.

This is a setup for the VLC that Arch packages, not a separate build of VLC.
It needs Omarchy (Hyprland with its Lua config).

To undo it, run bin/uninstall.

Source: https://github.com/neko-legends/omarchy-vlc
