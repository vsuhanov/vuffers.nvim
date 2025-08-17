# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Testing
- Run all tests: `make run-tests`
- Run single test file: `make run-test tests/filename_spec.lua`
- Tests use Plenary.nvim and require the minimal_init.lua configuration

### Code Formatting
- Format Lua code: `stylua .` (uses stylua.toml configuration)
- Style configuration: 2-space indentation, 120 column width, double quotes preferred

## Architecture Overview

Vuffers.nvim is a Neovim buffer management plugin written in Lua. The architecture follows a modular design:

### Core Module Structure
- **Main entry point**: `lua/vuffers.lua` - Exposes all public APIs and coordinates between modules
- **Configuration**: `lua/vuffers/config.lua` - Handles user configuration, defaults, and persistence
- **Buffer management**: `lua/vuffers/buffers/` - Core buffer tracking and manipulation logic
- **UI management**: `lua/vuffers/ui.lua`, `lua/vuffers/window.lua` - Window creation and display logic
- **Event system**: `lua/vuffers/event-bus.lua`, `lua/vuffers/subscriptions.lua` - Internal event handling

### Key Components
- **Buffer tracking**: Maintains list of open buffers with unique display names, pinning, and custom ordering
- **Display name resolution**: Automatically shortens file paths to minimal unique names (e.g., `foo/bar/baz.ts` becomes `baz` if unique)
- **Persistence**: Saves pinned buffers and configuration per working directory using JSON files
- **Event-driven updates**: Uses internal event bus for UI updates when buffers change

### Buffer State Management
- Active buffer tracking with highlighting
- Pinned buffers (persistent, shown at top)
- Custom display names (user-defined aliases)
- Custom ordering (drag/drop reordering)
- Sorting options (none, filename with asc/desc)

### UI Features
- Vertical buffer list window
- Auto-resize capability based on content
- Icon support for modified/pinned states
- Keymap-driven interactions within the buffer list
- Highlight groups for theming

### Dependencies
- Required: nvim-tree/nvim-web-devicons
- Optional: Tastyep/structlog.nvim (for enhanced logging)
- Testing: nvim-lua/plenary.nvim

### Session Integration
The plugin supports Neovim session restoration. When working with sessions, call `require("vuffers").on_session_loaded()` after session restore to properly restore buffer names and pinning state.

## File Organization Patterns
- Utility functions in `lua/utils/` (file, list, logger, string helpers)
- Core buffer logic in `lua/vuffers/buffers/` with clear separation of concerns
- UI-related modules handle window management and user interactions
- Configuration uses deep merging for user customization over defaults