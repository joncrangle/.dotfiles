#!/bin/bash

# This script is executed when either the mode changes,
# or the commandline changes

sketchybar --trigger svim_update MODE="$MODE" CMDLINE="$CMDLINE"
