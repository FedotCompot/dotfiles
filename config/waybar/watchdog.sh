#!/usr/bin/env bash
# restarts waybar when it is running but has lost its bars or stopped ticking
set -uo pipefail

unit=waybar.service
state="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-watchdog.state"
strikes_to_restart=2

systemctl --user is-active --quiet "$unit" || exit 0

pid=$(systemctl --user show -p MainPID --value "$unit")
[[ ${pid:-0} -gt 0 && -r "/proc/$pid/stat" ]] || exit 0

stat=$(</proc/"$pid"/stat)
# read past the parenthesised comm so a space in it cannot shift the field offsets
read -ra f <<< "${stat#*') '}"
(( ${#f[@]} >= 13 )) || exit 0
ticks=$(( f[11] + f[12] ))

hz=$(getconf CLK_TCK)
uptime_ticks=$(awk -v hz="$hz" '{printf "%d", $1 * hz}' /proc/uptime)
# a bar that just started has not mapped its surfaces yet
(( (uptime_ticks - f[19]) / hz < 20 )) && exit 0

prev_pid=0 prev_ticks=0 strikes=0
[[ -r $state ]] && read -r prev_pid prev_ticks strikes < "$state"
[[ $prev_pid == "$pid" ]] || { prev_ticks=0; strikes=0; }

bars=$(hyprctl -j layers 2>/dev/null | jq '[.. | objects | select(.namespace? == "waybar")] | length') || bars=-1
mons=$(hyprctl -j monitors 2>/dev/null | jq 'length') || mons=-1
# a probe that answered with anything but a count must not be allowed to vote
[[ $bars =~ ^[0-9]+$ ]] || bars=-1
[[ $mons =~ ^[0-9]+$ ]] || mons=-1

reason=""
# this config sets no "output" filter, so every monitor is meant to carry a bar
(( bars >= 0 && mons > 0 && bars < mons )) && reason="only $bars of $mons bars mapped"
(( prev_ticks > 0 && ticks == prev_ticks )) && reason="${reason:+$reason; }main loop burned no cpu since the last check"

if [[ -z $reason ]]; then
    printf '%s %s 0\n' "$pid" "$ticks" > "$state"
    exit 0
fi

(( ++strikes < strikes_to_restart )) && { printf '%s %s %s\n' "$pid" "$ticks" "$strikes" > "$state"; exit 0; }

echo "waybar unhealthy ($reason) — restarting"
printf '0 0 0\n' > "$state"
systemctl --user reset-failed "$unit" 2>/dev/null
systemctl --user --no-block restart "$unit"
