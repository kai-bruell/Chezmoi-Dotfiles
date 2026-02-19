#!/bin/bash
# Reload sway config after chezmoi applies changes

if command -v swaymsg &>/dev/null && [ -n "$SWAYSOCK" ]; then
    swaymsg reload
fi
