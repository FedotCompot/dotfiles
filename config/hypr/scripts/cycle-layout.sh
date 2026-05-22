#!/bin/bash
layouts=("dwindle" "master" "scroller" "monocle")
labels=("Dwindle" "Master" "Scrolling" "Monocle")

current=$(hyprctl getoption general:layout -j | jq -r '.str')

for i in "${!layouts[@]}"; do
    if [[ "${layouts[$i]}" == "$current" ]]; then
        next_i=$(( (i + 1) % ${#layouts[@]} ))
        hyprctl keyword general:layout "${layouts[$next_i]}"
        notify-send "Layout: ${labels[$next_i]}" -t 1500
        exit 0
    fi
done

hyprctl keyword general:layout "${layouts[0]}"
notify-send "Layout: ${labels[0]}" -t 1500
