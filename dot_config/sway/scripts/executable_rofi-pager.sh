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
