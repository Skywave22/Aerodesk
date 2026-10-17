# Changelog

All notable changes to this project are documented in this file. The format is
based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.1] - 2026-10-17

### Fixed
- Desktop icon grid no longer pushes the last column off the right edge: the
  column count is computed from the usable width minus the grid margin, which
  used to overflow on landscape windows whose width was not an exact multiple
  of the cell width.
- The dock no longer covers the last row of desktop icons. The desktop now
  reserves the dock height, and the dock scrolls horizontally instead of
  overflowing when it holds many entries.
- Icon positions saved on a smaller or rotated screen are re-flowed into the
  grid instead of being clamped into a corner, which is what made the desktop
  look ragged after a rotation.
- Dragging a desktop icon no longer writes settings to disk on every pointer
  move. The position is kept in local state and persisted once when the gesture
  ends, removing the drag stutter.
- Light wallpapers (Daylight, Sand, Mint) render dark icon labels and dark
  picker labels; white text on pale gradients was unreadable.
- The app launcher panel is sized from the window, so it no longer runs off the
  edge of short landscape windows.
- Card titles on the Device page ellipsise instead of overflowing narrow phone
  windows.
- Short windows (landscape phones, split screen) use the navigation rail
  instead of the bottom bar so the desktop keeps its height.

### Added
- Compact desktop icon cells on short windows, so landscape still shows more
  than one row of icons.
- Layout regression tests for phone portrait, phone landscape, tablet and
  large windows, plus an overflow scan over every section, module window and
  the launcher.

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
