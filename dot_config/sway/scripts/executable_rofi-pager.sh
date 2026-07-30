# Shared 3-Level Rofi Browser
# Source in consumer scripts:
#   source "$(dirname "$0")/rofi-pager.sh"

ROFI_THEME="${ROFI_THEME:-$HOME/.config/sway/scripts/launcher.rasi}"
KB_ACCEPT="Alt+l,Control+j,Control+m,Return"
KB_BACK="Alt+h"

rofi_dmenu() {
    local items="$1" prompt="$2" extra_args="${3:-}"
    echo "$items" | rofi -dmenu -i \
        -p "$prompt" \
        -kb-accept-entry "$KB_ACCEPT" \
        $extra_args \
        -theme "$ROFI_THEME"
}

rofi_categories() {
    local cat_output="$1" prompt="${2:-Category}"
    [ -z "$cat_output" ] && return 1
    rofi_dmenu "$cat_output" "$prompt" "-kb-cancel Escape"
}

rofi_entries() {
    local entry_output="$1" prompt="${2:-Entries}"
    [ -z "$entry_output" ] && return 1
    local selection
    selection=$(rofi_dmenu "$entry_output" "$prompt" "-kb-custom-1 $KB_BACK")
    local ec=$?
    [ $ec -eq 10 ] && return 10
    [ -z "$selection" ] && return 1
    echo "$selection"
    return 0
}

rofi_action() {
    local actions="$1" prompt="${2:-Action}"
    rofi_dmenu "$actions" "$prompt" "-kb-cancel Escape"
}

rofi_extract_key() {
    echo "$1" | awk -F'│' '{print $1}' | xargs
}

rofi_browse() {
    local app_name="$1"
    local cat entries entry ec
    cat=$(rofi_categories "$(get_categories)" "$app_name Keybindings")
    [ -z "$cat" ] && exit 0
    entries=$(get_entries "$cat")
    entry=$(rofi_entries "$entries" "$cat")
    ec=$?
    [ $ec -eq 10 ] && exec "$0"
    echo "$entry"
}

rofi_handle_entry() {
    local display="$1" line="$2" app="$3" config="$4"
    local key
    key=$(rofi_extract_key "$display")
    local action_label="2. Open in Nvim"
    [ -n "$line" ] && action_label="2. Open in Nvim (Line $line)"
    local action
    action=$(rofi_action "1. Copy Keybinding\n$action_label")
    [ -z "$action" ] && return 1
    case "$action" in
        "1. Copy"*)
            echo -n "$key" | wl-copy
            notify-send "$app Help" "Kopiert: $key"
            ;;
        "2. Open"*)
            [ -z "$line" ] && return 1
            foot -e nvim +"$line" "$config"
            ;;
    esac
}
