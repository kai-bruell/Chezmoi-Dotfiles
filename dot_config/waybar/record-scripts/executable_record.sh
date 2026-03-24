#!/usr/bin/env bash
# record.sh - Video aufnehmen oder streamen.
#
# Args:
#   $1  local <output.mkv>   - lokale Aufnahme
#   $1  stream <host:port>   - NUT-Stream per TCP
#   $2  wf-recorder Output-Name (z.B. DP-4); leer = automatisch
#
# Audio (nur local-Modus):
#   ffmpeg zeichnet beide Waybar-Sink-Monitore auf → <output>.mka (2 Tracks)
#   waybar_mic.monitor / waybar_snd.monitor sind gültige PA-Sources — ffmpeg
#   hängt sich korrekt daran und erscheint in qpwgraph an den Monitor-Outputs.

MODE="${1:-local}"
ARG2="${2:-}"
WF_OUTPUT="${3:-}"

WF_PID=""
AUDIO_PID=""

cleanup() {
    [ -n "$WF_PID" ]    && kill -SIGINT "$WF_PID"    2>/dev/null; wait "$WF_PID"    2>/dev/null
    [ -n "$AUDIO_PID" ] && kill -SIGINT "$AUDIO_PID" 2>/dev/null; wait "$AUDIO_PID" 2>/dev/null
}
trap cleanup EXIT INT TERM

args=()
[ -n "$WF_OUTPUT" ] && args+=(-o "$WF_OUTPUT")
export LIBVA_DRIVER_NAME=iHD
args+=(-r 30 -c h264_vaapi -d /dev/dri/renderD128 --no-dmabuf -p qp=28 -p bf=0 -D)

case "$MODE" in
    local)
        args+=(-f "$ARG2")
        wf-recorder "${args[@]}" &
        WF_PID=$!

        audio_out="${ARG2%.mkv}.mka"
        ffmpeg -nostdin -y \
            -f pulse -i waybar_mic.monitor \
            -f pulse -i waybar_snd.monitor \
            -map 0:a -map 1:a \
            -c:a libopus \
            -metadata:s:a:0 title=Mic \
            -metadata:s:a:1 title=Snd \
            "$audio_out" &
        AUDIO_PID=$!
        ;;
    stream)
        args+=(--muxer nut -f "tcp://${ARG2}")
        wf-recorder "${args[@]}" &
        WF_PID=$!
        ;;
esac

wait $WF_PID
