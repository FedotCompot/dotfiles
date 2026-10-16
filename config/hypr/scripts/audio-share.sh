#!/usr/bin/env bash
# plays audio on several outputs at once through a pipewire combine sink
set -uo pipefail

sink_name=watchparty
waybar_signal=9
previous_file="${XDG_RUNTIME_DIR:-/tmp}/audio-share-previous-sink"
checked="󰄵 " unchecked="󰄱 "

refresh_waybar() { pkill -RTMIN+"$waybar_signal" -x waybar; }
module_line() { pactl list short modules | awk -F'\t' -v s="sink_name=$sink_name" '$2 == "module-combine-sink" && index($3, s)'; }
combined_sinks() { module_line | grep -oP 'sinks=\K[^ \t]+' | tr ',' '\n'; }

declare -A descriptions
while IFS=$'\t' read -r name description; do
    descriptions[$name]=$description
done < <(pactl -f json list sinks | jq -r --arg self "$sink_name" '.[] | select(.name != $self) | "\(.name)\t\(.description)"')

start() {
    local -a selected=("$(pactl get-default-sink)")
    local share choice name

    while :; do
        share="▶ Share to ${#selected[@]} outputs"
        choice=$(
            ((${#selected[@]} > 1)) && echo "$share"
            for name in "${!descriptions[@]}"; do
                [[ " ${selected[*]} " == *" $name "* ]] && echo "$checked${descriptions[$name]}" || echo "$unchecked${descriptions[$name]}"
            done | sort
        )
        choice=$(wofi --dmenu --prompt "Outputs to play on" --lines 9 <<<"$choice") || exit 0
        [[ "$choice" == "$share" ]] && break

        for name in "${!descriptions[@]}"; do
            [[ "${choice#"$checked"}" == "${descriptions[$name]}" ]] && mapfile -t selected < <(printf '%s\n' "${selected[@]}" | grep -vxF "$name")
            [[ "${choice#"$unchecked"}" == "${descriptions[$name]}" ]] && selected+=("$name")
        done
    done

    pactl get-default-sink >"$previous_file"
    pactl load-module module-combine-sink sink_name="$sink_name" sinks="$(IFS=,; echo "${selected[*]}")" \
        latency_compensate=true sink_properties=device.description=Watchparty >/dev/null || exit 1
    pactl set-default-sink "$sink_name"
    refresh_waybar
    notify-send "Audio sharing on" "$(for name in "${selected[@]}"; do echo "${descriptions[$name]}"; done)" -t 3000
}

stop() {
    pactl unload-module "$(module_line | cut -f1)"
    local previous
    previous=$(cat "$previous_file" 2>/dev/null)
    [[ -n "$previous" && -v "descriptions[$previous]" ]] && pactl set-default-sink "$previous"
    refresh_waybar
    notify-send "Audio sharing off" -t 1500
}

case "${1:-toggle}" in
status)
    if [[ -n "$(module_line)" ]]; then
        combined_sinks | while read -r name; do echo "${descriptions[$name]:-$name}"; done |
            jq -Rsc 'split("\n") | map(select(. != "")) | {text: "󰓃 \(length)", class: "sharing", tooltip: "Playing on:\n\(join("\n"))\nClick to stop"}'
    else
        echo '{"text":""}'
    fi
    ;;
toggle)
    if [[ -n "$(module_line)" ]]; then stop; else start; fi
    ;;
*)
    echo "usage: ${0##*/} [toggle|status]" >&2
    exit 2
    ;;
esac
