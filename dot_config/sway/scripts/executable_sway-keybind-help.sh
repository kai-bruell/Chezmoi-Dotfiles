#!/usr/bin/env bash
src="$(dirname "$0")/rofi-pager.sh"; [ -f "$src" ] || src="$(dirname "$0")/executable_rofi-pager.sh"; source "$src"

CONFIG_FILE="$HOME/.config/sway/config"

get_categories() {
    awk '
        /^### / {
            gsub(/^###[ \t]+/, "")
            cat = $0
            next
        }
        /^[ \t]*bindsym/ && cat != "" {
            if (!seen[cat]++) print cat
        }
    ' "$CONFIG_FILE"
}

get_entries() {
    local cat="$1"
    awk -v cat="$cat" '
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
    ' "$CONFIG_FILE"
}

handle_entry() {
    local display="$1" line_num="$2"
    local binding
    binding=$(echo "$display" | awk -F'│' '{print $1}' | xargs)

    local action
    action=$(rofi_action "1. Copy Keybinding\n2. Open in Nvim (Line $line_num)")
    [ -z "$action" ] && return 1

    case "$action" in
        "1. Copy"*)
            echo -n "$binding" | wl-copy
            notify-send "Sway Help" "Kopiert: $binding"
            ;;
        "2. Open"*)
            foot -e nvim +"$line_num" "$CONFIG_FILE"
            ;;
    esac
}

main() {
    local cat entries entry ec binding line_num
    cat=$(rofi_categories "$(get_categories)" "Sway Keybindings")
    [ -z "$cat" ] && exit 0

    entries=$(get_entries "$cat")
    entry=$(rofi_entries "$entries" "$cat")
    ec=$?
    [ $ec -eq 10 ] && exec "$0"
    [ -z "$entry" ] && exit 0

    binding=$(echo "$entry" | awk -F'│' '{print $1}' | xargs)
    line_num=$(echo "$entries" | grep -F "$binding" | head -1 | awk -F'\t' '{print $1}')

    handle_entry "$entry" "$line_num"
}

main "$@"
