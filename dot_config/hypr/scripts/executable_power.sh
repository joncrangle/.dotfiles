#!/bin/bash
#  ____                        
# |  _ \ _____      _____ _ __ 
# | |_) / _ \ \ /\ / / _ \ '__|
# |  __/ (_) \ V  V /  __/ |   
# |_|   \___/ \_/\_/ \___|_|   
#                              

exit_hyprland() {
    echo ":: Exit"
    sleep 0.5
    killall -9 Hyprland
    sleep 2
}

lock_screen() {
    echo ":: Lock"
    sleep 0.5
    hyprlock    
}

reboot_system() {
    echo ":: Reboot"
    sleep 0.5
    systemctl reboot
}

shutdown_system() {
    echo ":: Shutdown"
    sleep 0.5
    systemctl poweroff
}

suspend_system() {
    echo ":: Suspend"
    sleep 0.5
    systemctl suspend    
}

hibernate_system() {
    echo ":: Hibernate"
    sleep 1
    systemctl hibernate    
}

# Check the first argument and call the corresponding function
if [[ "$1" == "exit" ]]; then
    exit_hyprland
elif [[ "$1" == "lock" ]]; then
    lock_screen
elif [[ "$1" == "reboot" ]]; then
    reboot_system
elif [[ "$1" == "shutdown" ]]; then
    shutdown_system
elif [[ "$1" == "suspend" ]]; then
    suspend_system
elif [[ "$1" == "hibernate" ]]; then
    hibernate_system
else
    # Interactive menu
    if [[ "$1" == "top-left" ]]; then
    SELECTION="$(printf "1 - Exit\n2 - Lock\n3 - Reboot\n4 - Shutdown\n5 - Suspend\n6 - Hibernate" | fuzzel -d -a "top-left" -l 6 -p "Power Menu: ")"
    else
    echo ":: Menu" >> ~/log # For debugging
    SELECTION="$(printf "1 - Exit\n2 - Lock\n3 - Reboot\n4 - Shutdown\n5 - Suspend\n6 - Hibernate" | fuzzel -d -l 6 -p "Power Menu: ")"
    fi

    case $SELECTION in
        *"Exit")
            exit_hyprland;;
        *"Lock")
            lock_screen;;
        *"Reboot")
            reboot_system;;
        *"Shutdown")
            shutdown_system;;
        *"Suspend")
            suspend_system;;
        *"Hibernate")
            hibernate_system;;
    esac
fi
