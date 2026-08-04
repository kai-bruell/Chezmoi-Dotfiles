#!/bin/sh
# Installiert Akku-Ladebegrenzung nach /etc/tmpfiles.d/
sudo cp ~/.local/share/battery-charge-limit.conf /etc/tmpfiles.d/
sudo systemd-tmpfiles --create /etc/tmpfiles.d/battery-charge-limit.conf
