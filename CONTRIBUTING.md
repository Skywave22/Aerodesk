# Contributing to AeroDesk

Thanks for helping improve AeroDesk. This project is a real, working Android
desktop environment — please keep it that way.

## Ground rules

- **AI-free.** Do not add AI APIs, models, chatbots, subscriptions or
  AI-related dependencies. The architecture must stay modular enough that AI
  could be added later, but it is never required.
- **Public APIs only.** Use supported Android APIs. Do not fake unsupported
  system-level window control or invent device telemetry; if a value is not
  available, show it as unavailable.
- **Privacy first.** No analytics, tracking, accounts or unnecessary
  permissions. Request the minimum permission a feature genuinely needs.
- **Lightweight.** Avoid heavy effects (blur, excessive animation) and new
  dependencies. Prefer Flutter's own capabilities over packages.
- **Honest status.** If you add a feature, update the feature status in the
  README and in Settings → About.

## Development setup

```bash
git clone https://github.com/Skywave22/Aerodesk.git
cd Aerodesk
flutter pub get
flutter run            # on a device or emulator
```

## Before opening a pull request

```bash
flutter analyze        # must report no issues
flutter test           # all tests must pass
flutter build apk --debug
```

Please test on a real device when possible — phones and tablets behave
differently for storage permissions, window sizing and external displays.

## Code style

- Dart: follow `flutter_lints`; the project enables a few extra rules (see
  `analysis_options.yaml`).
- Keep widgets small and prefer `const` constructors.
- Feature-first folder layout under `lib/features/`; shared code lives in
  `lib/core/`.
- State management: Riverpod. New persisted preferences belong in
  `AeroSettings` (and its `AeroSettings.fromJson` / `toJson` pair) so they
  survive restarts.
- Native additions go through the single `com.aerodesk/apps` method channel.

## Tests

- Unit tests for logic that has no UI (calculator engine, filesystem
  operations, settings serialisation).
- Widget tests for anything that renders. The smoke test shows the pattern:
  override `clockProvider` with a single-shot stream so no periodic timer keeps
  the test's fake clock alive, stub `filesRootsProvider` because `path_provider`
  needs a native platform, and answer the `com.aerodesk/apps` channel with null
  so the app behaves as it does without a native side.

## Commits and pull requests

- Small, focused commits with clear messages.
- Describe what you changed and why, and note the device/Android version you
  tested on.
- Breaking changes to the settings format need a migration, not a reset.

## Reporting bugs

Use the bug report template and include your device, Android version and
AeroDesk version from Settings → About.
