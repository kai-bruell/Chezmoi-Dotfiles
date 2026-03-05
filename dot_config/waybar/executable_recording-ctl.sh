#!/usr/bin/env bash
# recording-ctl.sh - Waybar video-recording module controller
#
# Runtime state (transient, /tmp/):
#   /tmp/waybar_rec_active      - file exists = recording active
#   /tmp/waybar_rec_start       - unix timestamp of recording start
#   /tmp/waybar_rec_pid         - PID of wf-recorder process
#   /tmp/waybar_rec_mic_muted   - file exists = microphone muted
#   /tmp/waybar_snd_muted   - file exists = system sound muted
#
# Persistent settings (~/.local/state/waybar-recording/):
#   streaming                   - file exists = streaming mode, otherwise recording mode
#   display                     - selected wf-recorder output (e.g. DP-4)
#   output-dir                  - recording output directory
#   server-addr                 - TCP streaming server address (IP:PORT)
#
# Audio-Sinks sind persistent (pipewire.conf.d/10-waybar-sinks.conf):
#   waybar_mic  →  waybar_mic.monitor  (Track 1)
#   waybar_snd  →  waybar_snd.monitor  (Track 2)
#   Verkabelung via qpwgraph.
#
# Usage:
#   recording-ctl.sh              - JSON output for Waybar (polled)
#   recording-ctl.sh toggle-rec   - start / stop recording or stream
#   recording-ctl.sh toggle-mic   - mute / unmute microphone (waybar_mic sink)
#   recording-ctl.sh toggle-snd   - mute / unmute system sound (waybar_snd sink)
#   recording-ctl.sh toggle-mode  - switch between recording and streaming mode

# Runtime state (lost on reboot — intentional)
REC_ACTIVE="/tmp/waybar_rec_active"
REC_START="/tmp/waybar_rec_start"
REC_PID="/tmp/waybar_rec_pid"
MIC_MUTED="/tmp/waybar_rec_mic_muted"
SND_MUTED="/tmp/waybar_snd_muted"

# Persistent settings
STATE_DIR="${HOME}/.local/state/waybar-recording"
STREAMING="${STATE_DIR}/streaming"
OUTPUT_SELECTED="${STATE_DIR}/display"
DIR_SELECTED="${STATE_DIR}/output-dir"
IP_SELECTED="${STATE_DIR}/server-addr"

mkdir -p "$STATE_DIR"

SCRIPT_DIR="$(dirname "$(realpath "$0")")/record-scripts"
REC_OUTPUT_DIR="${HOME}/Videos"
SERVER_ADDR="192.168.1.100:12345"

# ── Helper functions ─────────────────────────────────────────────────────────

is_recording()  { [ -f "$REC_ACTIVE" ]; }
is_mic_muted()  { [ -f "$MIC_MUTED" ]; }
is_snd_muted()  { [ -f "$SND_MUTED" ]; }
is_streaming()  { [ -f "$STREAMING" ]; }


get_output_label() {
    if [ -f "$OUTPUT_SELECTED" ]; then
        local name
        name=$(cat "$OUTPUT_SELECTED")
        swaymsg -t get_outputs | jq -r --arg n "$name" \
            '.[] | select(.name == $n) | .make + " " + .model + " (" + .name + ")"'
    else
        echo "not selected"
    fi
}

get_rec_dir() {
    [ -f "$DIR_SELECTED" ] && cat "$DIR_SELECTED" || echo "$REC_OUTPUT_DIR"
}

get_server_addr() {
    [ -f "$IP_SELECTED" ] && cat "$IP_SELECTED" || echo "$SERVER_ADDR"
}


get_elapsed() {
    if [ -f "$REC_START" ]; then
        start=$(cat "$REC_START")
        now=$(date +%s)
        elapsed=$(( now - start ))
        printf "%02d:%02d" $(( elapsed / 60 )) $(( elapsed % 60 ))
    else
        echo "00:00"
    fi
}

signal_waybar() {
    pkill -RTMIN+8 waybar 2>/dev/null
}

# ── Actions ──────────────────────────────────────────────────────────────────

do_start_recording() {
    if [ ! -f "$OUTPUT_SELECTED" ]; then
        notify-send -u normal "Recording" "No display selected — use context-menu → Select Display."
        return 1
    fi
    if is_streaming; then
        if [ ! -s "$IP_SELECTED" ]; then
            notify-send -u normal "Recording" "No streaming server set — use context-menu → Set Streaming IP."
            return 1
        fi
        local addr host port
        addr=$(get_server_addr)
        host="${addr%%:*}"
        port="${addr##*:}"
        if ! nc -z -w2 "$host" "$port" 2>/dev/null; then
            notify-send -u critical "Recording" "Streaming server $addr not reachable."
            return 1
        fi
    else
        if [ ! -s "$DIR_SELECTED" ]; then
            notify-send -u normal "Recording" "No output directory set — use context-menu → Set Output Directory."
            return 1
        fi
    fi

    local wf_output
    wf_output=$(cat "$OUTPUT_SELECTED")

    if is_streaming; then
        bash "$SCRIPT_DIR/record.sh" stream "$(get_server_addr)" "$wf_output" &
    else
        local rec_dir output
        rec_dir=$(get_rec_dir)
        mkdir -p "$rec_dir"
        output="${rec_dir}/recording_$(date +%Y-%m-%d_%H-%M-%S).mkv"
        bash "$SCRIPT_DIR/record.sh" local "$output" "$wf_output" &
    fi
    echo $! > "$REC_PID"
    touch "$REC_ACTIVE"
    date +%s > "$REC_START"
}

do_stop_recording() {
    # SIGINT → wf-recorder finalisiert die Datei sauber
    pkill -SIGINT wf-recorder 2>/dev/null || true
    pkill -SIGINT -f record.sh  2>/dev/null || true
    rm -f "$REC_PID" "$REC_ACTIVE" "$REC_START"
}

do_mute_mic() {
    touch "$MIC_MUTED"
}

do_unmute_mic() {
    rm -f "$MIC_MUTED"
}


do_select_output() {
    # Build "label|name" pairs from active sway outputs
    entries=$(swaymsg -t get_outputs | jq -r \
        '.[] | select(.active) | (.make + " " + .model + " (" + .name + ")") + "|" + .name')
    [ -z "$entries" ] && return

    selected_label=$(printf '%s\n' "$entries" | cut -d'|' -f1 \
        | rofi -dmenu -p "Output" -theme "$HOME/.config/sway/scripts/launcher.rasi")
    [ -z "$selected_label" ] && return

    selected_name=$(printf '%s\n' "$entries" \
        | awk -F'|' -v d="$selected_label" '$1 == d { print $2; exit }')
    [ -z "$selected_name" ] && return

    echo "$selected_name" > "$OUTPUT_SELECTED"
}

do_select_rec_dir() {
    local tmp
    tmp=$(mktemp --suffix=.txt)
    get_rec_dir > "$tmp"
    foot --app-id=waybar-editor -- nvim "$tmp"
    local val
    val=$(tr -d '[:space:]' < "$tmp")
    [ -n "$val" ] && tr -d '\n' < "$tmp" > "$DIR_SELECTED"
    rm -f "$tmp"
}

do_select_server_ip() {
    local tmp
    tmp=$(mktemp --suffix=.txt)
    get_server_addr > "$tmp"
    foot --app-id=waybar-editor -- nvim "$tmp"
    local val
    val=$(tr -d '[:space:]' < "$tmp")
    [ -n "$val" ] && tr -d '\n' < "$tmp" > "$IP_SELECTED"
    rm -f "$tmp"
}


do_mute_snd() {
    touch "$SND_MUTED"
    pactl set-source-mute waybar_snd.monitor true 2>/dev/null || true
}

do_unmute_snd() {
    rm -f "$SND_MUTED"
    pactl set-source-mute waybar_snd.monitor false 2>/dev/null || true
}

# ── Toggle logic ─────────────────────────────────────────────────────────────

case "$1" in
    toggle-rec)
        if is_recording; then
            do_stop_recording
        else
            do_start_recording
        fi
        signal_waybar
        exit 0
        ;;
    toggle-mic)
        if is_mic_muted; then
            do_unmute_mic
        else
            do_mute_mic
        fi
        signal_waybar
        exit 0
        ;;
    context-menu)
        snd_label=$(is_snd_muted && echo 'Unmute Audio' || echo 'Mute Audio')
        mode_label=$(is_streaming && echo 'Switch to Recording' || echo 'Switch to Streaming')
        menu=$(printf 'Select Display\n%s\nSet Output Directory\nSet Streaming IP' "$snd_label")
        ! is_recording && menu=$(printf '%s\n%s' "$menu" "$mode_label")
        choice=$(printf '%s' "$menu" \
            | rofi -dmenu -p "Recording" -theme "$HOME/.config/sway/scripts/launcher.rasi")
        case "$choice" in
            "Select Display")       do_select_output ;;
            "Mute Audio"|"Unmute Audio")
                is_snd_muted && do_unmute_snd || do_mute_snd ;;
            "Set Output Directory") do_select_rec_dir ;;
            "Set Streaming IP")     do_select_server_ip ;;
            "Switch to Streaming"|"Switch to Recording")
                is_streaming && rm -f "$STREAMING" || touch "$STREAMING" ;;
        esac
        signal_waybar
        exit 0
        ;;
    select-display)
        do_select_output
        signal_waybar
        exit 0
        ;;
    set-output-dir)
        do_select_rec_dir
        signal_waybar
        exit 0
        ;;
    set-server-ip)
        do_select_server_ip
        signal_waybar
        exit 0
        ;;
    toggle-snd)
        if is_snd_muted; then
            do_unmute_snd
        else
            do_mute_snd
        fi
        signal_waybar
        exit 0
        ;;
    --help|-h)
        echo "Usage: recording-ctl.sh [COMMAND]"
        echo ""
        echo "No argument: JSON output for Waybar"
        echo ""
        printf "%-20s %s\n" "Command" "Function"
        printf "%-20s %s\n" "--------------------" "-----------------------------"
        printf "%-20s %s\n" "toggle-mode"   "Recording <-> Streaming (only when stopped)"
        printf "%-20s %s\n" "toggle-rec"    "Start / Stop"
        printf "%-20s %s\n" "toggle-mic"    "Microphone mute / unmute"
        printf "%-20s %s\n" "toggle-snd"    "System sound mute / unmute"
        printf "%-20s %s\n" "select-display"  "Select capture display (screen) via rofi"
        printf "%-20s %s\n" "set-output-dir"  "Set recording output directory via rofi"
        printf "%-20s %s\n" "set-server-ip"   "Set TCP streaming server IP via rofi"
        printf "%-20s %s\n" "context-menu"    "Open recording context menu via rofi"
        exit 0
        ;;
    toggle-mode)
        # Only switchable when not recording/streaming
        if ! is_recording; then
            if is_streaming; then
                rm -f "$STREAMING"
            else
                touch "$STREAMING"
            fi
            signal_waybar
        fi
        exit 0
        ;;
esac

# ── Waybar JSON output ───────────────────────────────────────────────────────

if is_streaming; then
    mode_icon=$'\uf519'   # fa-tower-broadcast
    mode_class="mode-streaming"
else
    mode_icon=$'\uf03d'   # fa-video
    mode_class="mode-recording"
fi

if is_recording; then
    dot='<span color=\"#ff4444\">●</span>'
    timer=$(get_elapsed)
    rec_class="recording"
else
    dot='<span color=\"#888888\">●</span>'
    timer='--:--'
    rec_class="stopped"
fi

if is_mic_muted; then
    mic_icon=$'\uf131'   # fa-microphone-slash
    mic_class="mic-muted"
else
    mic_icon=$'\uf130'   # fa-microphone
    mic_class="mic-active"
fi
if is_snd_muted; then
    snd_icon=$'\uf6a9'   # fa-volume-xmark
    snd_class="snd-muted"
else
    snd_icon=$'\uf028'   # fa-volume-high
    snd_class="snd-active"
fi

text="$mode_icon  $dot $timer  $mic_icon  $snd_icon"
class="$rec_class $mode_class $mic_class $snd_class"
mic_tooltip=$(is_mic_muted && echo 'muted' || echo 'active')
snd_tooltip=$(is_snd_muted && echo 'muted' || echo 'active')
rec_dir_label=$([ -f "$DIR_SELECTED" ] && get_rec_dir || echo "not set")
server_addr_label=$([ -f "$IP_SELECTED" ] && get_server_addr || echo "not set")
tooltip="Display: $(get_output_label)\nMic (waybar_mic): $mic_tooltip\nSnd (waybar_snd): $snd_tooltip\n\nSave to: $rec_dir_label\nStream to: $server_addr_label\n\n$(is_streaming && echo 'Streaming' || echo 'Recording') $timer"

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
    "$text" "$class" "$tooltip"
