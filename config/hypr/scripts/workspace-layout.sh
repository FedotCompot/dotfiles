#!/bin/bash
# Change the active workspace's tiling layout.
#   pick  — choose from a wofi dmenu
#   cycle — advance to the next layout
layouts=("dwindle" "master" "scrolling" "monocle" "vertical" "horizontal")
lua_layouts=" vertical horizontal "  # registered in layouts.lua
state_dir="${XDG_RUNTIME_DIR:-/tmp}/hypr-workspace-layouts"

workspace=$(hyprctl activeworkspace -j)
name=$(jq -r '.name' <<<"$workspace")
state_file="$state_dir/${name//\//_}"
current=$(jq -r '.tiledLayout' <<<"$workspace")
# hyprctl reports every lua layout under the first registered name
[[ "$current" == lua:* ]] && current=$(cat "$state_file" 2>/dev/null)

case "$1" in
    pick)
        choice=$(
            for layout in "${layouts[@]}"; do
                [[ "$layout" == "$current" ]] && echo "$layout (current)" || echo "$layout"
            done | wofi --dmenu --prompt "Layout for workspace $name" --lines 7
        )
        next=${choice%% *}
        ;;
    cycle)
        next=${layouts[0]}
        for i in "${!layouts[@]}"; do
            [[ "${layouts[$i]}" == "$current" ]] && next=${layouts[$(( (i + 1) % ${#layouts[@]} ))]}
        done
        ;;
    *)
        echo "usage: $0 pick|cycle" >&2
        exit 2
        ;;
esac
[[ -z "$next" || "$next" == "$current" ]] && exit 0

layout=$next
[[ "$lua_layouts" == *" $next "* ]] && layout="lua:$next"
hyprctl eval "hl.workspace_rule({ workspace = \"name:$name\", layout = \"$layout\" })"
mkdir -p "$state_dir" && echo "$next" >"$state_file"
notify-send "Workspace $name: $next" -t 1500
