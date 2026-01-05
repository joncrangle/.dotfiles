#!/bin/sh
#  __  ______  ___  ____  ______
# (( \ | || | // \\ || \\ | || |
#  \\    ||   ||=|| ||_//   ||  
# \_))   ||   || || || \\   ||  

LOG="/tmp/hypr-autolock.log"
echo "Starting autolock at $(date)" > "$LOG"

# Wait for Hyprland
until hyprctl monitors &>/dev/null; do
    sleep 0.2
done
echo "Hyprland ready at $(date)" >> "$LOG"

# Wait for noctalia-shell instance (10 seconds max)
COUNT=0
until qs list -c noctalia-shell 2>/dev/null | grep -q "Instance" || [ "$COUNT" -ge 50 ]; do
    sleep 0.2
    COUNT=$((COUNT + 1))
done

if [ "$COUNT" -ge 50 ]; then
    echo "ERROR: noctalia-shell not found after 10 seconds" >> "$LOG"
    qs list --all >> "$LOG" 2>&1
    exit 1
fi

echo "noctalia-shell found at $(date)" >> "$LOG"

# Give IPC time to initialize, then lock (12.5 seconds max)
sleep 2
COUNT=0
until qs -c noctalia-shell ipc call lockScreen lock 2>> "$LOG" || [ "$COUNT" -ge 25 ]; do
    sleep 0.5
    COUNT=$((COUNT + 1))
done

if [ "$COUNT" -ge 25 ]; then
    echo "ERROR: Failed to lock after 25 attempts" >> "$LOG"
    exit 1
fi

echo "Lock successful at $(date)" >> "$LOG"
