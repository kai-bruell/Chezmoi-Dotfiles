#!/bin/bash

# Prüfen, ob mindestens ein Monitor aktiv ("dpms: On") ist
if swaymsg -t get_outputs | grep -q '"dpms": true'; then
    # Wenn an, dann ausschalten
    swaymsg "output * power off"
else
    # Wenn aus, dann einschalten
    swaymsg "output * power on"
fi
