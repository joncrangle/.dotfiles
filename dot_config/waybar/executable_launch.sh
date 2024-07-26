#!/bin/sh
# -----------------------------------------------------
# Quit all running waybar instances
# -----------------------------------------------------
killall waybar
pkill waybar
sleep 0.2

waybar &
