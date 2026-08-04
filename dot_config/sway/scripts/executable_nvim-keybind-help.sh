#!/usr/bin/env bash
src="$(dirname "$0")/rofi-pager.sh"; [ -f "$src" ] || src="$(dirname "$0")/executable_rofi-pager.sh"; source "$src"

CONFIG="$HOME/.config/nvim/lua/keymaps.lua"
APP="Nvim"

get_categories() {
    awk '/^-- \[\[BLOCK:/ { gsub(/^-- \[\[BLOCK: |\]\]$/,""); c=$0; h=0; next }
         /^-- \[\[\/BLOCK\]\]/ { if(h) print c; c=""; next }
         c!="" && /^-- cmd:/ { h=1 }' "$CONFIG"
}

get_entries() {
    awk -v c="$1" 'BEGIN{i=0}
         /^-- \[\[BLOCK:/ { gsub(/^-- \[\[BLOCK: |\]\]$/,""); i=($0==c); next }
         /^-- \[\[\/BLOCK\]\]/ { i=0 }
         i && /^-- cmd:/ { match($0,/^-- cmd:[ \t]+([^|]+)[ \t]*\|[ \t]*desc:[ \t]+(.+)$/,m);
             if(m[1]!="") printf "%-15s │ %s\n", m[1], m[2] }' "$CONFIG"
}

entry=$(rofi_browse "$APP")
[ -z "$entry" ] && exit 0
key=$(rofi_extract_key "$entry")
line=$(grep -nF -- "-- cmd: ${key} |" "$CONFIG" | head -1 | cut -d: -f1)
rofi_handle_entry "$entry" "$line" "$APP" "$CONFIG"
