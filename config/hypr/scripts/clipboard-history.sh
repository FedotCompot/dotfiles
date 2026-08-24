#!/bin/bash
# Clipboard history picker: list cliphist entries in a wofi dmenu,
# decode the chosen entry, and copy it back to the clipboard.
# The watcher that populates the history lives in autostart.lua.
cliphist list \
    | wofi --dmenu --prompt "Clipboard" --width 800 --height 500 \
    | cliphist decode \
    | wl-copy
