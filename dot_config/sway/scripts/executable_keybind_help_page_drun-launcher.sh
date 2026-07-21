#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/sway/config"
THEME="$HOME/.config/sway/scripts/launcher.rasi"

# 1. Config parsen: Zeilennummer, Keybinding und Kommentar (#) extrahieren
parsed_list=$(awk '
    /^[ \t]*bindsym/ {
        line_num = NR
        sub(/^[ \t]*bindsym[ \t]+/, "")
        
        # Falls ein Kommentar in derselben Zeile steht
        if (match($0, /#[ \t]*/)) {
            binding = substr($0, 1, RSTART - 1)
            desc = substr($0, RSTART + RLENGTH)
        } else {
            binding = $0
            desc = "No description"
        }
        
        # Formatierung säubern
        gsub(/[ \t]+$/, "", binding)
        gsub(/^[ \t]+|[ \t]+$/, "", desc)
        
        # Output: LineNumber | Binding | Description
        printf "%d\t%-30s\t# %s\n", line_num, binding, desc
    }
' "$CONFIG_FILE")

if [ -z "$parsed_list" ]; then
    notify-send "Sway Help" "Keine Keybindings in $CONFIG_FILE gefunden."
    exit 1
fi

# 2. Rofi Auswahlfenster (Spalte A: Binding, Spalte B: Description)
selected_line=$(echo "$parsed_list" | awk -F'\t' '{print $2 " │ " $3}' | rofi -dmenu -i -p "Keybindings Help" -theme "$THEME")

[ -z "$selected_line" ] && exit 0

# 3. Ausgewählte Zeilennummer und das reine Keybinding ermitteln
binding_text=$(echo "$selected_line" | awk -F'│' '{print $1}' | xargs)
line_num=$(echo "$parsed_list" | grep -F "$binding_text" | head -n1 | awk -F'\t' '{print $1}')

# 4. Aktionsmenü (Copy / Open in Nvim)
action=$(printf "1. Copy Keybinding\n2. Open in Nvim (Line %s)" "$line_num" | rofi -dmenu -i -p "Action" -theme "$THEME")

case "$action" in
    "1. Copy Keybinding"*)
        echo -n "$binding_text" | wl-copy
        notify-send "Sway Help" "Kopiert: $binding_text"
        ;;
    "2. Open in Nvim"*)
        foot -e nvim +"$line_num" "$CONFIG_FILE"
        ;;
esac
