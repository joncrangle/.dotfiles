#!/bin/sh
#  __  ______  ___  ____  ______
# (( \ | || | // \\ || \\ | || |
#  \\    ||   ||=|| ||_//   ||
# \_))   ||   || || || \\   ||

LOG="/tmp/hypr-autolock.log"
echo "Starting autolock at $(date)" >"$LOG"

# Wait for Hyprland
until hyprctl monitors >/dev/null 2>&1; do
    sleep 0.2
done
echo "Hyprland ready at $(date)" >>"$LOG"

# Wait for noctalia process to be running (10s max)
COUNT=0
until pgrep -x noctalia >/dev/null || [ "$COUNT" -ge 50 ]; do
    sleep 0.2
    COUNT=$((COUNT + 1))
done

if [ "$COUNT" -ge 50 ]; then
    echo "ERROR: noctalia process not found after 10 seconds" >>"$LOG"
    exit 1
fi
echo "noctalia process found at $(date)" >>"$LOG"

# Wait for Noctalia IPC to respond, then lock
COUNT=0
until noctalia msg session lock >>"$LOG" 2>&1 || [ "$COUNT" -ge 25 ]; do
    sleep 0.5
    COUNT=$((COUNT + 1))
done

if [ "$COUNT" -ge 25 ]; then
    echo "ERROR: Failed to lock via noctalia IPC after 25 attempts" >>"$LOG"
    # Fallback to hyprlock or loginctl lock-session if configured
    if command -v hyprlock >/dev/null 2>&1; then
        echo "Falling back to hyprlock..." >>"$LOG"
        exec hyprlock
    fi
    exit 1
fi

echo "Lock successful at $(date)" >>"$LOG"
