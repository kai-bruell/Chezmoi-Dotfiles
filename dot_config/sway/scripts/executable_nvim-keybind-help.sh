#!/usr/bin/env bash
source "$(dirname "$0")/rofi-pager.sh"

CONFIG_FILE="$HOME/.config/nvim/init.lua"

get_categories() {
    awk '
        /^-- \[\[BLOCK:/ {
            gsub(/^-- \[\[BLOCK: |\]\]$/, "")
            block_name = $0
            has_cmd = 0
            next
        }
        /^-- \[\[\/BLOCK\]\]/ {
            if (has_cmd) print block_name
            block_name = ""
            next
        }
        block_name != "" && /^-- cmd:/ {
            has_cmd = 1
        }
    ' "$CONFIG_FILE"
}

get_entries() {
    local cat="$1"
    awk -v cat="$cat" '
        BEGIN { in_block = 0 }
        /^-- \[\[BLOCK:/ {
            gsub(/^-- \[\[BLOCK: |\]\]$/, "")
            in_block = ($0 == cat)
            next
        }
        /^-- \[\[\/BLOCK\]\]/ { in_block = 0 }
        in_block && /^-- cmd:/ {
            match($0, /^-- cmd:[ \t]+([^|]+)[ \t]*\|[ \t]*desc:[ \t]+(.+)$/, m)
            if (m[1] != "") {
                gsub(/^[ \t]+|[ \t]+$/, "", m[1])
                gsub(/^[ \t]+|[ \t]+$/, "", m[2])
                printf "%-15s │ %s\n", m[1], m[2]
            }
        }
    ' "$CONFIG_FILE"
}

handle_entry() {
    local display="$1" cmd_line="$2"
    local key
    key=$(echo "$display" | awk -F'│' '{print $1}' | xargs)

    local action
    action=$(rofi_action "1. Copy Keybinding\n2. Open in Nvim")
    [ -z "$action" ] && return 1

    case "$action" in
        "1. Copy"*)
            echo -n "$key" | wl-copy
            notify-send "Nvim Help" "Kopiert: $key"
            ;;
        "2. Open"*)
            foot -e nvim +"$cmd_line" "$CONFIG_FILE"
            ;;
    esac
}

main() {
    local cat entries entry ec key cmd_line
    cat=$(rofi_categories "$(get_categories)" "Nvim Keybindings")
    [ -z "$cat" ] && exit 0

    entries=$(get_entries "$cat")
    entry=$(rofi_entries "$entries" "$cat")
    ec=$?
    [ $ec -eq 10 ] && exec "$0"
    [ -z "$entry" ] && exit 0

    key=$(echo "$entry" | awk -F'│' '{print $1}' | xargs)
    cmd_line=$(grep -nF "-- cmd: ${key} |" "$CONFIG_FILE" | head -1 | cut -d: -f1)

    handle_entry "$entry" "$cmd_line"
}

main "$@"
