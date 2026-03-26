#!/bin/bash
# Copyright (c) 2025-2026 Mikhail Matveev <xtreme@rh1.tech>
# Copyright (c) 2025-2026 DnCraptor <https://github.com/DnCraptor>
#
# release.sh - Build all release variants of FRANK Apple
#
# Creates firmware files for each combination (M1 and M2 boards):
#
# HDMI:
#   - RP2350 + PWM (PSRAM auto-enabled when available)
#   - RP2350 + I2S (PSRAM auto-enabled when available)
#   - RP2040 + PWM
#
# VGA:
#   - RP2350 + PWM (PSRAM auto-enabled when available)
#   - RP2350 + I2S (PSRAM auto-enabled when available)
#   - RP2040 + PWM
#
# Total: 12 builds (6 configs x 2 boards)
# Output: Individual .uf2 files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Version file
VERSION_FILE="version.txt"

# Accept version from command line
if [[ $# -ge 1 ]]; then
    INPUT_VERSION="$1"
else
    # Read last version or initialize
    if [[ -f "$VERSION_FILE" ]]; then
        read -r LAST_MAJOR LAST_MINOR < "$VERSION_FILE"
    else
        LAST_MAJOR=1
        LAST_MINOR=0
    fi

    # Calculate next version (for default suggestion)
    NEXT_MINOR=$((LAST_MINOR + 1))
    NEXT_MAJOR=$LAST_MAJOR
    if [[ $NEXT_MINOR -ge 100 ]]; then
        NEXT_MAJOR=$((NEXT_MAJOR + 1))
        NEXT_MINOR=0
    fi

    # Interactive version input
    DEFAULT_VERSION="${NEXT_MAJOR}.$(printf '%02d' $NEXT_MINOR)"
    read -p "Enter version [default: $DEFAULT_VERSION]: " INPUT_VERSION
    INPUT_VERSION=${INPUT_VERSION:-$DEFAULT_VERSION}
fi

echo ""
echo -e "${CYAN}┌─────────────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│                   FRANK Apple Release Builder                   │${NC}"
echo -e "${CYAN}└─────────────────────────────────────────────────────────────────┘${NC}"
echo ""

# Parse version (handle both "1.00" and "1 00" formats)
if [[ "$INPUT_VERSION" == *"."* ]]; then
    MAJOR="${INPUT_VERSION%%.*}"
    MINOR="${INPUT_VERSION##*.}"
else
    read -r MAJOR MINOR <<< "$INPUT_VERSION"
fi

# Remove leading zeros for arithmetic, then re-pad
MINOR=$((10#$MINOR))
MAJOR=$((10#$MAJOR))

# Validate
if [[ $MAJOR -lt 1 ]]; then
    echo -e "${RED}Error: Major version must be >= 1${NC}"
    exit 1
fi
if [[ $MINOR -lt 0 || $MINOR -ge 100 ]]; then
    echo -e "${RED}Error: Minor version must be 0-99${NC}"
    exit 1
fi

# Format version string
VERSION="${MAJOR}_$(printf '%02d' $MINOR)"
echo ""
echo -e "${GREEN}Building release version: ${MAJOR}.$(printf '%02d' $MINOR)${NC}"

# Save new version
echo "$MAJOR $MINOR" > "$VERSION_FILE"

# Create release directory
RELEASE_DIR="$SCRIPT_DIR/release"
mkdir -p "$RELEASE_DIR"

# Configuration
BOARDS=("M1" "M2")
VIDEO_TYPES=("HDMI" "VGA")
CPU_SPEED="252"  # No overclocking in release
PSRAM_SPEED="100"  # Default PSRAM speed (auto-enabled when available)

# Count total builds: 2 video * (2 UF2 + 1 RP2040) * 2 boards = 12
TOTAL_BUILDS=12
BUILD_COUNT=0

echo ""
echo -e "${YELLOW}Building $TOTAL_BUILDS firmware variants...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Function to build a single variant
build_variant() {
    local BOARD=$1
    local VIDEO=$2
    local AUDIO=$3
    local PLATFORM=$4   # "rp2350" or "rp2040"

    BUILD_COUNT=$((BUILD_COUNT + 1))

    # Determine board number for filename
    local BOARD_NUM=1
    [[ "$BOARD" == "M2" ]] && BOARD_NUM=2

    # Determine PICO_BOARD
    local PICO_BOARD="pico2"
    [[ "$PLATFORM" == "rp2040" ]] && PICO_BOARD="pico"

    # Build output filename
    local VIDEO_LC=$(echo "$VIDEO" | tr '[:upper:]' '[:lower:]')
    local AUDIO_LC=$(echo "$AUDIO" | tr '[:upper:]' '[:lower:]')

    # Determine file extension and name suffix
    local EXT="uf2"
    local TYPE_TAG="${PLATFORM}"

    local OUTPUT_NAME="frank_apple_m${BOARD_NUM}_${VIDEO_LC}_${AUDIO_LC}_${TYPE_TAG}_${VERSION}.${EXT}"

    echo ""
    echo -e "${CYAN}[$BUILD_COUNT/$TOTAL_BUILDS] Building: $OUTPUT_NAME${NC}"
    echo -e "  Board: $BOARD | Video: $VIDEO | Audio: $AUDIO | Platform: $PLATFORM"

    # Clean and create build directory
    rm -rf build bin/Release
    mkdir -p build bin/Release
    cd build

    # Build cmake arguments
    local CMAKE_ARGS="-DPICO_BOARD=$PICO_BOARD"
    CMAKE_ARGS="$CMAKE_ARGS -DBOARD_VARIANT=$BOARD"
    CMAKE_ARGS="$CMAKE_ARGS -DVIDEO_TYPE=$VIDEO"
    CMAKE_ARGS="$CMAKE_ARGS -DAUDIO_TYPE=$AUDIO"
    CMAKE_ARGS="$CMAKE_ARGS -DCPU_SPEED=$CPU_SPEED"

    # PSRAM auto-enabled for RP2350 builds (runtime detection)
    [[ "$PLATFORM" == "rp2350" ]] && CMAKE_ARGS="$CMAKE_ARGS -DPSRAM_SPEED=$PSRAM_SPEED"

    # Configure with CMake
    if cmake $CMAKE_ARGS .. > /dev/null 2>&1; then
        # Build
        if make -j8 > /dev/null 2>&1; then
            # Find and copy output file
            local SRC_FILE=""
            SRC_FILE=$(find "$SCRIPT_DIR/bin/Release" -maxdepth 1 -name "*.uf2" -type f 2>/dev/null | head -1)

            if [[ -n "$SRC_FILE" && -f "$SRC_FILE" ]]; then
                cp "$SRC_FILE" "$RELEASE_DIR/$OUTPUT_NAME"
                echo -e "  ${GREEN}✓ Success${NC} → release/$OUTPUT_NAME"
            else
                echo -e "  ${RED}✗ Output file not found${NC}"
            fi
        else
            echo -e "  ${RED}✗ Build failed${NC}"
        fi
    else
        echo -e "  ${RED}✗ CMake failed${NC}"
    fi

    cd "$SCRIPT_DIR"
}

# ============================================================================
# Build all variants
# ============================================================================

for VIDEO in "${VIDEO_TYPES[@]}"; do
    echo ""
    echo -e "${CYAN}=== Building $VIDEO variants ===${NC}"

    for BOARD in "${BOARDS[@]}"; do
        # RP2350 with PWM (PSRAM auto-enabled)
        build_variant "$BOARD" "$VIDEO" "PWM" "rp2350"

        # RP2350 with I2S (PSRAM auto-enabled)
        build_variant "$BOARD" "$VIDEO" "I2S" "rp2350"

        # RP2040 with PWM (no PSRAM)
        build_variant "$BOARD" "$VIDEO" "PWM" "rp2040"
    done
done

# ============================================================================
# Clean up
# ============================================================================
rm -rf build bin

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}Release build complete!${NC}"
echo ""
echo "Release files in: $RELEASE_DIR/"
echo ""
ls -la "$RELEASE_DIR"/frank_apple_*_${VERSION}.* 2>/dev/null | awk '{print "  " $9 " (" $5 " bytes)"}'
echo ""
echo -e "Version: ${CYAN}${MAJOR}.$(printf '%02d' $MINOR)${NC}"
