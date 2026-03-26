/*
 * disk_ui.h
 * 
 * Simple text-based disk selector UI for FRANK Apple
 */

#ifndef DISK_UI_H
#define DISK_UI_H

#include <stdint.h>
#include <stdbool.h>

// Forward declaration
struct mii_t;

// UI state
typedef enum {
    DISK_UI_HIDDEN,
    DISK_UI_SELECT_DRIVE,   // Selecting which drive (1 or 2)
    DISK_UI_SELECT_FILE,    // Selecting disk image file
    DISK_UI_SELECT_ACTION,  // Selecting action: Boot, Insert, or Cancel
    DISK_UI_LOADING,        // Loading disk from SD card
} disk_ui_state_t;

// Initialize disk UI with emulator pointer
// mii: pointer to the emulator instance
// disk2_slot: slot number where disk2 card is installed (usually 6)
void disk_ui_init_with_emulator(struct mii_t *mii, int disk2_slot);

// Legacy init (for backwards compatibility, won't mount disks)
void disk_ui_init(void);

// Show the disk selector (called on F11)
void disk_ui_show(void);

// Hide the disk selector (called on Esc)
void disk_ui_hide(void);

// Toggle visibility
void disk_ui_toggle(void);

// Handle key press in disk UI
// Returns true if key was consumed
bool disk_ui_handle_key(uint8_t key);

// Render the disk UI overlay to framebuffer
// Called from video rendering loop
void disk_ui_render(uint8_t *framebuffer, int width, int height);

// Check if UI is visible
bool disk_ui_is_visible(void);

// Check if UI needs redraw
bool disk_ui_needs_redraw(void);

// Get currently selected drive (0 or 1)
int disk_ui_get_selected_drive(void);

// Show loading screen
void disk_ui_show_loading(void);

#endif // DISK_UI_H
