#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/sway/config"
THEME="$HOME/.config/sway/scripts/launcher.rasi"

categories=$(awk '
    /^### / {
        gsub(/^###[ \t]+/, "")
        cat = $0
        next
    }
    /^[ \t]*bindsym/ && cat != "" {
        if (!seen[cat]++) print cat
    }
' "$CONFIG_FILE")

[ -z "$categories" ] && exit 0

selected_cat=$(echo "$categories" | rofi -dmenu -i -p "Sway Keybindings" -kb-accept-entry "Alt+l,Control+j,Control+m,Return" -theme "$THEME")
[ -z "$selected_cat" ] && exit 0

entries=$(awk -v cat="$selected_cat" '
    BEGIN { in_cat = 0 }
    /^### / {
        gsub(/^###[ \t]+/, "")
        in_cat = ($0 == cat)
        next
    }
    /^[ \t]*bindsym/ && in_cat {
        line_num = NR
        sub(/^[ \t]*bindsym[ \t]+/, "")
        if (match($0, /#[ \t]*/)) {
            binding = substr($0, 1, RSTART - 1)
            desc = substr($0, RSTART + RLENGTH)
        } else {
            binding = $0
            desc = "No description"
        }
        gsub(/[ \t]+$/, "", binding)
        gsub(/^[ \t]+|[ \t]+$/, "", desc)
        printf "%d\t%-30s\t# %s\n", line_num, binding, desc
    }
' "$CONFIG_FILE")

[ -z "$entries" ] && exec "$0"

selected_line=$(echo "$entries" | awk -F'\t' '{print $2 " │ " $3}' | rofi -dmenu -i -p "$selected_cat" -kb-custom-1 "Alt+h" -kb-accept-entry "Alt+l,Control+j,Control+m,Return" -theme "$THEME")
exit_code=$?
[ $exit_code -eq 10 ] && exec "$0"
[ -z "$selected_line" ] && exit 0

binding_text=$(echo "$selected_line" | awk -F'│' '{print $1}' | xargs)
line_num=$(echo "$entries" | grep -F "$binding_text" | head -n1 | awk -F'\t' '{print $1}')

action=$(printf "1. Copy Keybinding\n2. Open in Nvim (Line %s)" "$line_num" | rofi -dmenu -i -p "Action" -kb-accept-entry "Alt+l,Control+j,Control+m,Return" -theme "$THEME")
[ -z "$action" ] && exit 0

case "$action" in
    "1. Copy Keybinding"*)
        echo -n "$binding_text" | wl-copy
        notify-send "Sway Help" "Kopiert: $binding_text"
        ;;
    "2. Open in Nvim"*)
        foot -e nvim +"$line_num" "$CONFIG_FILE"
        ;;
esac
