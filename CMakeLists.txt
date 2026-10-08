# == DO NOT EDIT THE FOLLOWING LINES for the Raspberry Pi Pico VS Code Extension to work ==
if(WIN32)
    set(USERHOME $ENV{USERPROFILE})
else()
    set(USERHOME $ENV{HOME})
endif()
set(sdkVersion 2.2.0)
set(toolchainVersion 14_2_Rel1)
set(picotoolVersion 2.2.0)
set(picoVscode ${USERHOME}/.pico-sdk/cmake/pico-vscode.cmake)
if (EXISTS ${picoVscode})
    include(${picoVscode})
endif()
# ====================================================================================
cmake_minimum_required(VERSION 3.13)

set(BUILD_NAME "frank_apple")

set(BUILD_VERSION "1.05")

# Set board to Pico 2 (RP2350)
set(PICO_BOARD pico2 CACHE STRING "Board type")

# Board configuration variant (M1, M2, PC, Z2)
set(BOARD_VARIANT "Z2" CACHE STRING "Board variant: M1, M2, PC or Z2")

if(BOARD_VARIANT STREQUAL "Z2")
    # Waveshare RP2350-PiZero: RP2350B (48 GPIOs). The stock pico2 board header
    # declares RP2350A, which caps GPIOs at 0..29 and disables the PIO GPIO base,
    # so HDMI on GPIO32..39 and microSD on GPIO30..43 would not work.
    set(PICO_BOARD_HEADER_DIRS ${CMAKE_CURRENT_LIST_DIR}/boards CACHE PATH "" FORCE)
    set(PICO_BOARD waveshare_rp2350_pizero CACHE STRING "Board type" FORCE)
endif()

# CPU overclock configuration (252, 378, 504 MHz)
set(CPU_SPEED "378" CACHE STRING "CPU clock in MHz: 252, 378, 504")

set(VIDEO_TYPE "HDMI" CACHE STRING "Video output: HDMI or VGA")

if(VIDEO_TYPE STREQUAL "HDMI")
    set(VIDEO_HDMI ON)
elseif(VIDEO_TYPE STREQUAL "VGA")
    set(VIDEO_VGA ON)
endif()

# Audio output configuration (I2S, PWM or PWME)
set(AUDIO_TYPE "I2S" CACHE STRING "Audio output: I2S, PWM or PWME")

# PSRAM speed configuration (84, 100, 133, 166 MHz target)
# Leave unset for no-PSRAM builds
if(PICO_BOARD STREQUAL "pico2")
    set(PSRAM_SPEED "84" CACHE STRING "PSRAM max frequency in MHz: 84, 100, 133, 166")
endif()

# CPU voltage selection based on speed
if(CPU_SPEED GREATER_EQUAL 504)
    set(CPU_VOLTAGE "VREG_VOLTAGE_1_65")
elseif(CPU_SPEED GREATER_EQUAL 378)
    set(CPU_VOLTAGE "VREG_VOLTAGE_1_60")
else()
    set(CPU_VOLTAGE "VREG_VOLTAGE_1_50")
endif()

# I2S Audio pin configuration based on board variant
# PIO/SM for I2S: HDMI uses PIO1, PS/2 uses PIO0 SM0 on M1/M2/PC,
# so I2S takes PIO0 SM2. On Z2 HDMI takes PIO0 (GPIO base 16) and
# I2S gets PIO1 to itself (pico-extras audio_i2s accepts only PIO0/PIO1);
# PS/2 and the NES gamepad move to PIO2.
set(I2S_PIO "0")
set(I2S_SM "2")
if(BOARD_VARIANT STREQUAL "M1")
    set(I2S_DATA_PIN "26")
    set(I2S_CLOCK_PIN_BASE "27")
elseif(BOARD_VARIANT STREQUAL "M2")
    set(I2S_DATA_PIN "9")
    set(I2S_CLOCK_PIN_BASE "10")
elseif(BOARD_VARIANT STREQUAL "PC")
    # PCp2 adaptation currently uses the board's analog PWM L/R output.
    if(NOT AUDIO_TYPE STREQUAL "PWM")
        message(FATAL_ERROR "BOARD_VARIANT=PC currently supports AUDIO_TYPE=PWM only")
    endif()
elseif(BOARD_VARIANT STREQUAL "Z2")
    # External PCM5102A I2S DAC: DIN=GP10, BCK=GP11, LRCK=GP12 (as murm386 BOARD_Z2)
    if(NOT AUDIO_TYPE STREQUAL "I2S")
        message(FATAL_ERROR "BOARD_VARIANT=Z2 supports AUDIO_TYPE=I2S only (the board has no analog output)")
    endif()
    set(I2S_DATA_PIN "10")
    set(I2S_CLOCK_PIN_BASE "11")
    set(I2S_PIO "1")
    set(I2S_SM "0")
else()
    message(FATAL_ERROR "Unknown BOARD_VARIANT=${BOARD_VARIANT}; expected M1, M2, PC or Z2")
endif()

# USB HID Host support (keyboard and gamepad via USB)
# When enabled, USB CDC stdio is disabled!
option(USB_HID_ENABLED "Enable USB HID Host for keyboard/gamepad" ON)

# PS/2 keyboard support toggle
option(PS2_KEYBOARD_ENABLED "Enable PS/2 keyboard input" ON)

# Verbose debug logging toggle
option(DEBUG_LOGS_ENABLED "Enable verbose debug logging" OFF)

message(STATUS "FRANK Apple - Apple IIe Emulator for RP2350")
if (PSRAM_SPEED)
    message(STATUS "Board: ${BOARD_VARIANT}, CPU: ${CPU_SPEED} MHz, PSRAM: ${PSRAM_SPEED} MHz, Voltage: ${CPU_VOLTAGE}")
else ()
    message(STATUS "Board: ${BOARD_VARIANT}, CPU: ${CPU_SPEED} MHz, Voltage: ${CPU_VOLTAGE}")
endif ()
message(STATUS "I2S Audio: DATA=${I2S_DATA_PIN}, CLK_BASE=${I2S_CLOCK_PIN_BASE}")

include(pico_sdk_import.cmake)

# Import pico-extras for audio_i2s library
set(PICO_EXTRAS_PATH ${CMAKE_CURRENT_LIST_DIR}/pico-extras CACHE PATH "Path to pico-extras")
if(EXISTS ${PICO_EXTRAS_PATH}/external/pico_extras_import.cmake)
    include(${PICO_EXTRAS_PATH}/external/pico_extras_import.cmake)
endif()

set(OUTPUT_DIR "${CMAKE_SOURCE_DIR}/bin/${CMAKE_BUILD_TYPE}")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${OUTPUT_DIR}")

IF(BOARD_VARIANT STREQUAL "PC")
    if (NOT PICO_BOARD STREQUAL "pico2")
        message(FATAL_ERROR "BOARD_VARIANT=PC is the PCp2 target and requires PICO_BOARD=pico2")
    endif()
    SET(BUILD_NAME "PCp2-${BUILD_NAME}")
ELSEIF(BOARD_VARIANT STREQUAL "Z2")
    SET(BUILD_NAME "z0p2-${BUILD_NAME}")
ELSEIF(BOARD_VARIANT STREQUAL "M2")
    if (PICO_BOARD STREQUAL "pico")
        SET(BUILD_NAME "m2p1-${BUILD_NAME}")
    else()
        SET(BUILD_NAME "m2p2-${BUILD_NAME}")
    endif()
ELSE()
    if (PICO_BOARD STREQUAL "pico")
        SET(BUILD_NAME "m1p1-${BUILD_NAME}")
    else()
        SET(BUILD_NAME "m1p2-${BUILD_NAME}")
    endif()
endif ()

IF(VIDEO_VGA)
    SET(BUILD_NAME "${BUILD_NAME}-VGA")
endif ()
IF(VIDEO_HDMI)
    SET(BUILD_NAME "${BUILD_NAME}-HDMI")
endif ()

SET(BUILD_NAME "${BUILD_NAME}-${CPU_SPEED}MHz")

if (PICO_BOARD STREQUAL "pico2")
    if (PSRAM_SPEED)
        SET(BUILD_NAME "${BUILD_NAME}-P${PSRAM_SPEED}")
    endif ()
endif ()

SET(BUILD_NAME "${BUILD_NAME}-${AUDIO_TYPE}-${BUILD_VERSION}")


project(${BUILD_NAME} C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

# Initialize pico-extras if available
if(COMMAND pico_extras_init)
    pico_extras_init()
endif()

# Copy driver subdirectories from murmdoom structure
add_subdirectory(drivers/ps2kbd)
add_subdirectory(drivers/fatfs)
add_subdirectory(drivers/sdcard)
if(USB_HID_ENABLED)
    add_subdirectory(drivers/usbhid)
endif()

# Collect driver sources based on configuration
set(DRIVER_SOURCES drivers/nespad/nespad.c)

if (PSRAM_SPEED)
    list(APPEND DRIVER_SOURCES
        drivers/psram_init.c
        drivers/psram_allocator.c
    )
endif()

if (VIDEO_HDMI)
    list(APPEND DRIVER_SOURCES drivers/HDMI.c)
endif()

if (VIDEO_VGA)
    list(APPEND DRIVER_SOURCES drivers/vga.c)
endif()

# Create a library for drivers
add_library(drivers ${DRIVER_SOURCES})

target_include_directories(drivers PUBLIC drivers drivers/nespad src)
target_compile_definitions(drivers PRIVATE
    BOARD_${BOARD_VARIANT}
    $<$<STREQUAL:${BOARD_VARIANT},PC>:PICO_PC=1>
)

if (PSRAM_SPEED)
    target_compile_definitions(drivers PRIVATE
        PSRAM_MAX_FREQ_MHZ=${PSRAM_SPEED}
    )
endif()

# Apple IIe Emulator sources
add_executable(${BUILD_NAME}
    src/main.c
    src/mii_65c02.c
    src/mii_bank.c
    src/mii_video.c
    src/mii_rom.c
    src/mii.c
    src/mii_rom_iiee.c
    src/mii_rom_iiee_video.c
    src/disk_loader.c
    src/disk_ui.c
    src/mii_startscreen.c
    src/mii_analog.c
    # Disk drive support
    src/mii_slot.c
    src/mii_dd_stub.c
    src/mii_floppy.c
    src/mii_disk2.c
    src/mii_dsk.c
    src/mii_nib.c
    src/mii_woz.c
    src/mii_vcd_stub.c
    src/mii_rom_disk2_p5.c

    src/mii_smartport.c

    # Audio support
    src/mii_audio_i2s.c
    # Note: mii_speaker.c is excluded - stub provided in main.c for RP2350
    src/mii_audio.c
#mockingboard
#    src/mii_mb.c
#    src/mockingboard.c
)

if (PICO_BOARD STREQUAL "pico")
    pico_define_boot_stage2(slower_boot2 ${PICO_DEFAULT_BOOT_STAGE2_FILE})
    target_compile_definitions(slower_boot2 PRIVATE PICO_FLASH_SPI_CLKDIV=4)
    pico_set_boot_stage2(${BUILD_NAME} slower_boot2)
else()
    # RP2350: Use custom linker script
    pico_set_linker_script(${PROJECT_NAME} "${CMAKE_SOURCE_DIR}/memmap.ld")
endif()

target_link_libraries(drivers pico_stdlib hardware_dma hardware_pio hardware_spi hardware_pwm)

target_include_directories(${BUILD_NAME} PRIVATE
    src
    drivers
)

target_compile_definitions(${BUILD_NAME} PRIVATE
    BOARD_${BOARD_VARIANT}
    $<$<STREQUAL:${BOARD_VARIANT},PC>:PICO_PC=1>
    CPU_CLOCK_MHZ=${CPU_SPEED}
    CPU_VOLTAGE=${CPU_VOLTAGE}
    MII_65C02_DIRECT_ACCESS=1
    MII_RP2350=1
    # I2S Audio configuration
    # NOTE: HDMI uses PIO1, PS/2 uses PIO0 SM0 (claimed dynamically)
    # So I2S uses PIO0 SM2 (claimed statically before PS/2 init)
    PICO_AUDIO_I2S_PIO=${I2S_PIO}
    PICO_AUDIO_I2S_STATE_MACHINE=${I2S_SM}
    PICO_AUDIO_I2S_DMA_IRQ=1
    PICO_AUDIO_I2S_DMA_CHANNEL=10
    PICO_AUDIO_I2S_DATA_PIN=${I2S_DATA_PIN}
    PICO_AUDIO_I2S_CLOCK_PIN_BASE=${I2S_CLOCK_PIN_BASE}
)

if (PICO_BOARD STREQUAL "pico2")
    if (PSRAM_SPEED)
        target_compile_definitions(${BUILD_NAME} PRIVATE
            PSRAM_MAX_FREQ_MHZ=${PSRAM_SPEED}
        )
    endif()
endif()

# Audio configuration based on AUDIO_TYPE
if(AUDIO_TYPE STREQUAL "I2S")
    target_compile_definitions(${BUILD_NAME} PRIVATE
        # I2S Audio configuration
        # NOTE: HDMI uses PIO1, PS/2 uses PIO0 SM0 (claimed dynamically)
        # So I2S uses PIO0 SM2 (claimed statically before PS/2 init)
        PICO_AUDIO_I2S_PIO=${I2S_PIO}
        PICO_AUDIO_I2S_STATE_MACHINE=${I2S_SM}
        PICO_AUDIO_I2S_DMA_IRQ=1
        PICO_AUDIO_I2S_DMA_CHANNEL=10
        PICO_AUDIO_I2S_DATA_PIN=${I2S_DATA_PIN}
        PICO_AUDIO_I2S_CLOCK_PIN_BASE=${I2S_CLOCK_PIN_BASE}
        FEATURE_AUDIO_I2S=1
    )
elseif(AUDIO_TYPE STREQUAL "PWM")
    target_compile_definitions(${BUILD_NAME} PRIVATE
        FEATURE_AUDIO_PWM=1
    )
elseif(AUDIO_TYPE STREQUAL "PWME")
    target_compile_definitions(${BUILD_NAME} PRIVATE
        FEATURE_AUDIO_PWM_BEEPER=1
    )
endif()

if (VIDEO_HDMI)
    target_compile_definitions(${BUILD_NAME} PRIVATE
        VIDEO_HDMI
        VIDEO=HDMI
    )
endif()

if (VIDEO_VGA)
    target_compile_definitions(${BUILD_NAME} PRIVATE
        VIDEO_VGA
        VIDEO=VGA
    )
endif()

if(PS2_KEYBOARD_ENABLED)
    target_compile_definitions(${BUILD_NAME} PRIVATE ENABLE_PS2_KEYBOARD=1)
else()
    target_compile_definitions(${BUILD_NAME} PRIVATE ENABLE_PS2_KEYBOARD=0)
endif()

if(DEBUG_LOGS_ENABLED)
    target_compile_definitions(${BUILD_NAME} PRIVATE ENABLE_DEBUG_LOGS=1)
else()
    target_compile_definitions(${BUILD_NAME} PRIVATE ENABLE_DEBUG_LOGS=0)
endif()

# Optimization for maximum performance on RP2350
# -O3: Maximum optimization including loop vectorization
# -ffunction-sections -fdata-sections: Allow linker to remove unused code
# -flto: Link-time optimization for cross-file inlining
# -fno-strict-aliasing: Allow type punning (common in emulators)
# -march=armv8-m.main+fp+dsp: Target Cortex-M33 architecture
target_compile_options(${BUILD_NAME} PRIVATE 
    -O3
    -ffunction-sections 
    -fdata-sections
    -fno-strict-aliasing
)

target_link_libraries(${BUILD_NAME}
    pico_stdlib
    pico_multicore
    pico_audio_i2s
    hardware_dma
    hardware_pio
    hardware_clocks
    hardware_vreg
    hardware_spi
    drivers
    ps2kbd
    sdcard
    fatfs
)

if(USB_HID_ENABLED)
    target_link_libraries(${BUILD_NAME} usbhid)
endif()

# USB CDC stdio: enabled for debugging, but disabled when USB HID is enabled
# (USB port can only be Host OR Device, not both)
if(USB_HID_ENABLED)
    pico_enable_stdio_usb(${BUILD_NAME} 0)
    message(STATUS "USB CDC stdio disabled (USB HID Host is enabled)")
else()
    pico_enable_stdio_usb(${BUILD_NAME} 1)
endif()
pico_enable_stdio_uart(${BUILD_NAME} 1)

# Create UF2 output
pico_add_extra_outputs(${BUILD_NAME})

target_link_options(${BUILD_NAME} PRIVATE -Xlinker --print-memory-usage --data-sections)
