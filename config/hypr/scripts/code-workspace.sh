#!/bin/bash
hyprctl dispatch layoutmsg "mfact exact 0.75"

# Guard against on_created_empty re-firing (e.g. when monitors change and the
# workspace is recreated): only spawn VSCode if no Code window is already open.
if hyprctl clients -j | grep -Eq '"(initialClass|class)": *"(code-url-handler|[Cc]ode|[Cc]odium|VSCodium)"'; then
    exit 0
fi
exec code
