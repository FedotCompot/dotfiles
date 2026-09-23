#!/usr/bin/env bash
# decodes barcodes in a selected screen region and copies the content
set -uo pipefail

geometry=$(slurp) || exit 0
mapfile -t codes < <(grim -g "$geometry" - | ZXingReader -json - 2>/dev/null | jq -r '.. | objects | select(has("Text")) | .Text')

if (( ${#codes[@]} == 0 )); then
    notify-send -u low -t 2500 "QR scan" "No code found in the selection"
    exit 1
fi

text=$(printf '%s\n' "${codes[@]}")
printf '%s' "$text" | wl-copy

body=${text//&/&amp;}
body=${body//</&lt;}
if (( ${#codes[@]} == 1 )) && [[ $text =~ ^https?:// ]]; then
    action=$(notify-send -t 8000 -A open=Open "QR code copied" "$body")
    if [[ $action == open ]]; then xdg-open "$text"; fi
else
    notify-send -t 5000 "QR code copied" "$body"
fi
