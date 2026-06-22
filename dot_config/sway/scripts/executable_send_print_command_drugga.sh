#!/bin/bash
if [[ "$1" =~ \.(md|txt|csv)$ ]]; then
    if [[ "$1" =~ \.csv$ ]]; then
        tr ',' '\t' < "$1"
    else
        pandoc "$1" -t plain
    fi | lpr -o number-up=2 -o sides=two-sided-long-edge -o cpi=12 -o lpi=8
else
    echo "Fehler: Nur .md, .txt oder .csv"
    exit 1
fi
