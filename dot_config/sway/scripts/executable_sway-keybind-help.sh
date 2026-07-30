#!/usr/bin/env bash
src="$(dirname "$0")/rofi-pager.sh"; [ -f "$src" ] || src="$(dirname "$0")/executable_rofi-pager.sh"; source "$src"

CONFIG="$HOME/.config/sway/config"
APP="Sway"

get_categories() {
    awk '/^### / { gsub(/^###[ \t]+/,""); if(!seen[$0]++) print }' "$CONFIG"
}

get_entries() {
    awk -v c="$1" 'BEGIN{i=0}
         /^### / { gsub(/^###[ \t]+/,""); i=($0==c); next }
         /^[ \t]*bindsym/ && i {
             sub(/^[ \t]*bindsym[ \t]+/,"")
             if(match($0,/#[ \t]*/)) { b=substr($0,1,RSTART-1); d=substr($0,RSTART+RLENGTH) }
             else { b=$0; d="" }
             gsub(/[ \t]+$/,"",b); gsub(/^[ \t]+|[ \t]+$/,"",d)
             printf "%-20s │ %s\n", b, d
         }' "$CONFIG"
}

entry=$(rofi_browse "$APP")
[ -z "$entry" ] && exit 0
key=$(rofi_extract_key "$entry")
line=$(grep -n "bindsym[[:space:]]\+$key\([[:space:]]\|$\)" "$CONFIG" | head -1 | cut -d: -f1)
[ -z "$line" ] && line=$(grep -n "^[[:space:]]*$key[[:space:]]" "$CONFIG" | head -1 | cut -d: -f1)
rofi_handle_entry "$entry" "$line" "$APP" "$CONFIG"
