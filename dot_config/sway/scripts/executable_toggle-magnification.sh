#!/usr/bin/env bash
#
# toggle-magnification.sh
# Schaltet den wooz-Magnifier (Wayland-Lupe) ein/aus.
# wooz läuft in einer Toolbox, wird aber vom Host-Sway aus getriggert,
# da der Wayland-Socket zwischen Host und Toolbox geteilt wird.

set -euo pipefail

# Name der Toolbox anpassen (leer lassen für die Standard-Toolbox)
TOOLBOX_NAME="${TOOLBOX_NAME:-fedora-toolbox-43}"

BIN="wooz"
# Optionen: 100% Zoom, Lupe folgt der Maus
WOOZ_ARGS=(--zoom-in 33% --mouse-track)

if pgrep -x "$BIN" >/dev/null 2>&1; then
    # Läuft bereits -> beenden
    pkill -x "$BIN"
else
    # Starten (im Hintergrund, damit das Skript sofort zurückkehrt)
    toolbox run --container "$TOOLBOX_NAME" "$BIN" "${WOOZ_ARGS[@]}" &
    disown
fi
