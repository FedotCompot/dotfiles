#!/usr/bin/env bash
# toggles a wf-recorder region capture and keeps the waybar indicator in sync
set -uo pipefail

dir="$HOME/Videos/ScreenRecording"
waybar_signal=8

refresh_waybar() { pkill -RTMIN+"$waybar_signal" -x waybar; }
recording() { pgrep -x wf-recorder >/dev/null; }

case "${1:-toggle}" in
status)
    if recording; then
        since=$(ps -o lstart= -C wf-recorder | head -1 | xargs -I{} date -d {} +%H:%M:%S)
        printf '{"text":"󰑊 REC","class":"recording","tooltip":"Recording since %s\\nClick to stop"}\n' "$since"
    else
        echo '{"text":""}'
    fi
    ;;
toggle)
    if recording; then
        pkill -INT -x wf-recorder
        exit 0
    fi
    geometry=$(slurp) || exit 0
    mkdir -p "$dir"
    file="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
    wf-recorder -g "$geometry" -f "$file" &
    refresh_waybar
    wait
    refresh_waybar
    notify-send "Screen recording saved" "$file" -t 3000
    ;;
*)
    echo "usage: ${0##*/} [toggle|status]" >&2
    exit 2
    ;;
esac
