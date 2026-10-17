import 'package:flutter/material.dart';

/// Destinations shown in the AeroDesk navigation rail / navigation bar.
enum ShellSection { workspace, files, settings, device }

extension ShellSectionLabel on ShellSection {
  String get label => switch (this) {
        ShellSection.workspace => 'Workspace',
        ShellSection.files => 'Files',
        ShellSection.settings => 'Settings',
        ShellSection.device => 'Device',
      };

  IconData get icon => switch (this) {
        ShellSection.workspace => Icons.desktop_windows_outlined,
        ShellSection.files => Icons.folder_outlined,
        ShellSection.settings => Icons.tune_outlined,
        ShellSection.device => Icons.phone_android_outlined,
      };

  IconData get selectedIcon => switch (this) {
        ShellSection.workspace => Icons.desktop_windows,
        ShellSection.files => Icons.folder,
        ShellSection.settings => Icons.tune,
        ShellSection.device => Icons.phone_android,
      };
}
