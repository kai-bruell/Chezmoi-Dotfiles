#!/usr/bin/env bash
# stream-receiver.sh - Streaming-Empfänger: läuft auf dem Homelab-Server.
# Zuerst starten — wartet auf Verbindung vom Sender.
# Stoppt automatisch wenn der Sender beendet wird.

PORT="${1:-12345}"
OUTPUT="${2:-recording_$(date +%Y-%m-%d_%H-%M-%S).mkv}"

echo "Warte auf Sender auf Port ${PORT} ..."
echo "Ausgabedatei: ${OUTPUT}"
echo "KEIN Ctrl+C hier nötig — Datei wird automatisch finalisiert wenn der Sender stoppt."

# -listen 1     → TCP-Server-Modus, wartet auf Sender-Verbindung
# -c copy       → Kein Re-Encoding
# -bsf:v h264_metadata=video_full_range_flag=1
#               → Setzt Full-Range-Flag im H.264 VUI-Header ohne Re-Encoding;
#                  stellt sicher, dass Player den Stream als PC/Full-Range (0-255) interpretieren
ffmpeg \
    -loglevel warning \
    -listen 1 \
    -i "tcp://0.0.0.0:${PORT}" \
    -c copy \
    -bsf:v h264_metadata=video_full_range_flag=1 \
    "${OUTPUT}"

echo "Aufnahme gespeichert: ${OUTPUT}"
