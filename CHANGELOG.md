# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.0] - 2026-10-17

Initial release of AeroDesk.

### Added
- Desktop workspace with wallpaper, draggable desktop icons and four virtual
  workspaces with a switcher in the top bar.
- Internal window manager: drag, resize, minimise, maximise, restore, focus
  handling, snap layouts (left, right, top, bottom, quarters) and running-module
  indicators in the dock.
- App launcher with search, pinned apps, a recently used list and app info,
  grouped into AeroDesk modules and installed applications.
- AeroFiles file manager: browse, list and grid views, sort by name/type/size/
  date, in-folder search, create folder, create file, rename, copy and move into
  a chosen destination folder, delete with confirmation, file details and
  open-with through FileProvider.
- Built-in workspace modules: autosaving Notes, a Calculator with keyboard
  support, and a Clock with an analog face, a stopwatch with laps and a
  countdown timer.
- Settings: theme mode, seven accent colours, eight wallpapers, dock size and
  auto-hide, desktop icon labels, sorting and open gesture, window snapping and
  animations, launcher pins, shortcut reference and reset to defaults.
- Device information page limited to values exposed by public Android APIs
  (device, software, display, battery, storage, memory), with unavailable
  telemetry shown as "Unknown" instead of being estimated.
- Keyboard and mouse support: workspace, window and calculator shortcuts,
  hover states, right-click context menus and pointer drag/resize.
- GitHub Actions workflow that analyses, tests and builds a debug APK, plus an
  optional signed release workflow triggered by version tags.
- Unit tests (calculator engine, filesystem operations, settings persistence)
  and widget smoke tests for the shell, a module window, the settings page, the
  files page and the device page without a native platform.

### Notes
- AI-free by design: no AI APIs, models or subscriptions are included.
- Shared storage browsing requires all-files access on Android 11+, granted at
  runtime from system settings; the app-private folder always works.
