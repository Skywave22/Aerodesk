import 'package:flutter/widgets.dart';

import '../device/device_page.dart';
import '../files/files_page.dart';
import '../modules/calculator/calculator_page.dart';
import '../modules/clock/clock_page.dart';
import '../modules/notes/notes_page.dart';
import '../settings/settings_page.dart';

/// Builds the content of a module window.
///
/// Windows reuse the exact page widgets used by the navigation rail, so the
/// two views cannot drift apart.
Widget buildModule(BuildContext context, String id) {
  switch (id) {
    case 'files':
      return const FilesPage();
    case 'notes':
      return const NotesPage();
    case 'calculator':
      return const CalculatorPage();
    case 'clock':
      return const ClockPage();
    case 'settings':
      return const SettingsPage();
    case 'device':
      return const DevicePage();
    default:
      return const SizedBox.shrink();
  }
}
