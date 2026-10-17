# AeroDesk

**A lightweight, AI-free Android desktop environment and productivity workspace.**

AeroDesk turns an Android phone or tablet into a desktop-like workspace: a
wallpaper, draggable desktop icons, a dock, an app launcher, a real internal
window manager with snap layouts, and built-in productivity modules — all in a
single Flutter app that stays fast on low- and mid-range hardware.

AeroDesk is built with **Flutter + Dart** for the UI and **Kotlin** for native
Android integration (app launching, storage volumes, device details, file
sharing) through a single method channel.

> **AI-free by design.** There are no AI APIs, models, chatbots or
> subscriptions in this project. The architecture is modular, so AI features
> could be evaluated in a future version — but they will never be required for
> the core workspace to function.

---

## Feature status

### Implemented and verified

| Area | What works |
| --- | --- |
| Desktop workspace | Wallpaper, draggable desktop icons in a grid that reserves space for the dock and adapts to short windows (compact cells), saved positions that re-flow when the window changes size, 4 virtual workspaces with a switcher |
| Window manager | Drag, resize, minimise, maximise/restore, close, focus management, snap layouts (left / right / quarters), taskbar badges in the dock |
| App launcher | Search, pinned apps, recently used list, app info and launch, grouped into AeroDesk modules and installed applications; the panel is sized to the window and states plainly that installed apps start in the system |
| AeroFiles | Browse, list and grid views, sort by name/type/size/date, in-folder search, create folder, create file, rename, copy and move into a chosen destination, delete with confirmation, file details, open-with through FileProvider, multi-select |
| Workspace modules | Notes (autosaving), Calculator (expression engine plus keyboard input), Clock (live analog and digital face, stopwatch with laps, countdown timer) |
| Settings | Theme mode, 7 accent colours, 8 wallpapers (icon labels and picker swatches switch colour for light wallpapers so text stays readable), dock size and auto-hide, desktop icon labels, sorting and open gesture, window snapping and animations, launcher pins, shortcut reference, reset to defaults |
| Device info | Manufacturer, model, board, hardware, Android version, SDK level, security patch, CPU cores, window size, resolution, density, refresh rate, storage, RAM, battery — all from public APIs |
| Input | Keyboard shortcuts (workspaces, windows, calculator), hover states, right-click context menus on the desktop, icons and window title bars |
| Persistence | Every preference, launcher pin, note and desktop icon position is stored locally with SharedPreferences and restored on restart (recently used apps are per session) |
| Quality | 43 unit and widget tests (including layout regression tests for phone, landscape and large windows), `flutter analyze` clean, debug APK builds locally and in CI |

### Experimental (works, device-dependent)

| Feature | Notes |
| --- | --- |
| Large-screen layout | The shell adapts to phones, tablets and wide or external-display windows (navigation rail from 840 dp width or below 460 dp height, labels from 1180 dp). Android desktop mode behaviour varies by OEM. |
| Window snapping | Half, quarter and maximise layouts on the internal window manager. |
| Physical keyboard/mouse | Fully supported where Android delivers the events; some system shortcuts stay with the OS. |

### Planned (not implemented)

| Feature | Notes |
| --- | --- |
| Managing external app windows | **Not possible with public Android APIs.** No supported API lets one app embed another app's Activity in its own window (`ACTIVITY_EMBEDDING`, `ActivityView` and `setLaunchDisplayId` need system privileges), so installed apps start in the system launcher while AeroDesk modules run in AeroDesk windows. |
| Home-screen replacement | Registering as a default HOME/LAUNCHER app is not enabled in v1. |
| Additional workspace modules | More built-in tools can be added through the module registry. |
| Release signing pipeline | The workflow exists; it needs repository secrets (see below). |

---

## Screenshots

_Coming soon — the project currently ships without screenshot assets._

---

## Project structure

```
lib/
  main.dart                          App entry point; provides SharedPreferences
  app/
    app.dart                         Root widget, theming, shell host
    router.dart                      Shell section enum (workspace/files/settings/device)
  core/
    constants/aero_constants.dart    Shared constants (channel name, grid, workspaces)
    models/
      app_info.dart                  Installed app metadata
      file_entry.dart                Filesystem entry
    services/
      apps_service.dart              Method channel: apps, storage, device, file open
      files_service.dart             Filesystem operations and storage roots
      settings_service.dart          Persisted preferences (Riverpod notifier)
      device_service.dart            Device snapshot from the native channel
      calculator_engine.dart         Dependency-free expression evaluator
      clock_service.dart             One-second clock stream
    utils/formatting.dart            Time, date, stopwatch and size formatting
    widgets/                         Panels, settings tiles, pickers, empty states
  theme/
    accent_colors.dart               Selectable accent colours
    wallpapers.dart                  Built-in gradient wallpapers
    aerodesk_theme.dart              Material 3 theme and spacing tokens
  features/
    workspace/
      aerodesk_shell.dart            Responsive shell, navigation and shortcuts
      desktop/                       Desktop view, wallpaper, draggable icons
      dock/                          Dock, app launcher overlay
      windows/                       Window state, window chrome, snap layouts
      widgets/                       Top bar and workspace switcher
    modules/
      module_registry.dart           Module metadata used by dock and windows
      module_builders.dart           Window content for each module
      notes/                         Autosaving notes
      calculator/                    Calculator and keypad
      clock/                         World clock, stopwatch and timer
    files/                           AeroFiles page and widgets
    settings/                        Appearance, behaviour, shortcuts, About
    device/                          Device information page

android/app/src/main/
  kotlin/com/aerodesk/aerodesk/
    MainActivity.kt                  Flutter host and channel registration
    AppsChannel.kt                   Native implementations
  AndroidManifest.xml                Package visibility, storage permission, FileProvider
  res/                              Adaptive launcher icon, themes, file provider paths

test/
  unit/                              Calculator engine, filesystem, settings
  widget/                            Shell, window, files and device smoke tests
```

State management uses **Riverpod**; preferences are persisted as a single JSON
document in **SharedPreferences**. The design system is **Material 3** with a
custom AeroDesk theme (seeded from the selected accent colour) and no blur
effects, so it stays smooth on budget devices.

---

## Building

### Requirements

- Flutter 3.47.x (stable) with Dart 3.13
- JDK 17
- Android SDK with platform 34 or newer and matching build tools
- `minSdk` 26 (Android 8.0), `targetSdk` from the Flutter toolchain

### Local build

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
# output: build/app/outputs/flutter-apk/app-debug.apk
```

Install on a connected device:

```bash
flutter install
# or
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Continuous integration

Every push and pull request runs `.github/workflows/build-apk.yml`, which
analyses the code, runs the tests, builds a debug APK and uploads it as the
`aerodesk-debug-apk` artifact — download it from the workflow run summary.

### Signing a release build

Release builds need an upload keystore. Create one and add these **repository
secrets** (Settings → Secrets and variables → Actions):

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |

Then push a version tag (`git tag v1.0.0 && git push origin v1.0.0`); the
`release-apk.yml` workflow builds and attaches the signed APK to the release.
`android/key.properties` and `*.jks` files are git-ignored — never commit them.

---

## Permissions and privacy

| Permission | Why |
| --- | --- |
| `MANAGE_EXTERNAL_STORAGE` | Browse shared storage in AeroFiles on Android 11+. Requested at runtime from system settings; the app-private folder always works without it. |
| Package visibility (`<queries>`) | List launchable apps in the launcher, limited to apps that declare a launcher entry point. |

AeroDesk has **no analytics, no tracking, no accounts and no network calls**.
The `INTERNET` permission is declared only in the debug and profile manifests
because the Flutter tool needs it for hot reload; release builds do not request
it. Files are opened by sharing them through `FileProvider`, so the receiving
app never gets filesystem access. Everything the app knows about you stays on
the device.

---

## Keyboard and mouse

| Input | Action |
| --- | --- |
| `Ctrl + K` | Open the app launcher |
| `Ctrl + 1…4` | Switch workspace |
| `Ctrl + [` / `Ctrl + ]` | Previous / next workspace |
| `Ctrl + M` | Minimise the focused window |
| `Ctrl + W` or `Escape` | Close the focused window |
| `F11` | Maximise or restore the focused window |
| `0…9`, `+ - * / % ^ ( )` | Calculator input (Enter calculates) |
| `Right click` | Context menu for the desktop, an icon or a window title bar |
| `Double click` | Open an item, or maximise/restore a window |
| `Drag title bar` | Move a window |
| `Drag window corner` | Resize a window |

System shortcuts (navigation gestures, Recents, notification shade) are always
left to Android.

---

## Roadmap

1. **Foundation** — project scaffold, design system, responsive shell, persistent settings. ✅
2. **Core workspace** — dock, launcher, window controls, keyboard and mouse navigation. ✅
3. **Productivity** — AeroFiles, customisation settings, device info and About. ✅
4. **Native integration** — external displays and Android desktop-mode investigation. 🔬 (device-dependent, documented as experimental)
5. **Testing and release** — phones and tablets, permission and storage verification, debug APK and release signing docs. ✅ (release signing awaits repository secrets)

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). In short: `flutter analyze` and
`flutter test` must pass, keep dependencies minimal, never add AI APIs or
tracking, and update the feature status tables above when a feature changes
state.

## License

[MIT](LICENSE) © 2026 AeroDesk contributors.
