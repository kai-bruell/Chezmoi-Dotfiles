#!/bin/sh
SCRIPT_DIR="$HOME/.config/aider"
[ -x "$HOME/.local/bin/aider" ] || {
    python3 -m venv "$SCRIPT_DIR/venv"
    "$SCRIPT_DIR/venv/bin/pip" install --upgrade pip
    "$SCRIPT_DIR/venv/bin/pip" install aider-install
    "$SCRIPT_DIR/venv/bin/aider-install"
}
exec "$HOME/.local/bin/aider" "$@"
