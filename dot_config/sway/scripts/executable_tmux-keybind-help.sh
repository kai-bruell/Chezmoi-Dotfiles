#!/usr/bin/env bash

CONFIG_FILE="$HOME/.tmux.conf"
THEME="$HOME/.config/sway/scripts/launcher.rasi"

categories=$(awk '
    /^# \[\[BLOCK:/ {
        gsub(/^# \[\[BLOCK: |\]\]$/, "")
        block_name = $0
        has_cmd = 0
        next
    }
    /^# \[\[\/BLOCK\]\]/ {
        if (has_cmd) print block_name
        block_name = ""
        next
    }
    block_name != "" && /^# cmd:/ {
        has_cmd = 1
    }
' "$CONFIG_FILE")

[ -z "$categories" ] && exit 0

selected_cat=$(echo "$categories" | rofi -dmenu -i -p "Tmux Keybindings" -kb-accept-entry "Alt+l,Control+j,Control+m,Return" -theme "$THEME")
[ -z "$selected_cat" ] && exit 0

entries=$(awk -v cat="$selected_cat" '
    BEGIN { in_block = 0 }
    /^# \[\[BLOCK:/ {
        gsub(/^# \[\[BLOCK: |\]\]$/, "")
        in_block = ($0 == cat)
        next
    }
    /^# \[\[\/BLOCK\]\]/ { in_block = 0 }
    in_block && /^# cmd:/ {
        match($0, /^# cmd:[ \t]+([^|]+)[ \t]*\|[ \t]*desc:[ \t]+(.+)$/, m)
        if (m[1] != "") {
            gsub(/^[ \t]+|[ \t]+$/, "", m[1])
            gsub(/^[ \t]+|[ \t]+$/, "", m[2])
            printf "%-15s │ %s\n", m[1], m[2]
        }
    }
' "$CONFIG_FILE")

[ -z "$entries" ] && exec "$0"

selected_entry=$(echo "$entries" | rofi -dmenu -i -p "$selected_cat" -kb-custom-1 "Alt+h" -kb-accept-entry "Alt+l,Control+j,Control+m,Return" -theme "$THEME")
exit_code=$?
[ $exit_code -eq 10 ] && exec "$0"
[ -z "$selected_entry" ] && exit 0

key=$(echo "$selected_entry" | awk -F'│' '{print $1}' | xargs)

action=$(printf "1. Copy Keybinding\n2. Open in Nvim" | rofi -dmenu -i -p "Action" -kb-accept-entry "Alt+l,Control+j,Control+m,Return" -theme "$THEME")
[ -z "$action" ] && exit 0

case "$action" in
    "1. Copy Keybinding"*)
        echo -n "$key" | wl-copy
        notify-send "Tmux Help" "Kopiert: $key"
        ;;
    "2. Open in Nvim"*)
        line_num=$(grep -nF "# cmd: ${key} |" "$CONFIG_FILE" | head -1 | cut -d: -f1)
        foot -e nvim +"$line_num" "$CONFIG_FILE"
        ;;
esac
