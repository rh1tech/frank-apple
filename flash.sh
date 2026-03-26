#!/bin/bash
# Flash FRANK Apple to connected Pico device

if [ -n "$1" ]; then
    FIRMWARE="$1"
else
    # Find the newest .uf2 in the build directory
    FIRMWARE=$(ls -t ./build/*.uf2 2>/dev/null | head -1)
    if [ -z "$FIRMWARE" ]; then
        echo "Error: No .uf2 file found in ./build/"
        echo "Usage: $0 [firmware.uf2]"
        exit 1
    fi
fi

if [ ! -f "$FIRMWARE" ]; then
    echo "Error: $FIRMWARE not found"
    exit 1
fi

echo "Flashing: $FIRMWARE"
picotool load -f "$FIRMWARE" && picotool reboot -f
