#!/bin/bash
# Pick a tiling layout for the active workspace from a wofi dmenu.
layouts=("dwindle" "master" "scrolling" "monocle")

workspace=$(hyprctl activeworkspace -j)
name=$(jq -r '.name' <<<"$workspace")
current=$(jq -r '.tiledLayout' <<<"$workspace")

choice=$(
    for layout in "${layouts[@]}"; do
        [[ "$layout" == "$current" ]] && echo "$layout (current)" || echo "$layout"
    done | wofi --dmenu --prompt "Layout for workspace $name" --lines 5
)
choice=${choice%% *}
[[ -z "$choice" || "$choice" == "$current" ]] && exit 0

hyprctl eval "hl.workspace_rule({ workspace = \"name:$name\", layout = \"$choice\" })"
notify-send "Workspace $name: $choice" -t 1500
