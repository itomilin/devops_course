#!/usr/bin/env bash

# pip3 install flask --break-system-packages

p_id=$( pidof dunst )

if [[ -z $p_id ]]; then
  echo "Start dunst..."
  dunst || true &
fi

python3 ./main.py

