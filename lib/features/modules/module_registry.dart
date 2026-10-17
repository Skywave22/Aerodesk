import 'package:flutter/material.dart';

/// Identifiers of the modules that can run inside a desktop window.
enum ModuleId { files, notes, calculator, clock, settings, device }

/// Static description of one module.
class ModuleDefinition {
  const ModuleDefinition({
    required this.id,
    required this.title,
    required this.icon,
    required this.summary,
  });

  final String id;
  final String title;
  final IconData icon;
  final String summary;

  ModuleId get moduleId => ModuleId.values.firstWhere((value) => value.name == id, orElse: () => ModuleId.files);
}

/// Ordered list of modules offered by the dock and the app launcher.
///
/// Keep this list in sync with the navigation sections in
/// `lib/app/router.dart`.
const List<ModuleDefinition> kModules = <ModuleDefinition>[
  ModuleDefinition(
    id: 'files',
    title: 'AeroFiles',
    icon: Icons.folder_outlined,
    summary: 'Browse, open, copy, move, rename and delete files',
  ),
  ModuleDefinition(
    id: 'notes',
    title: 'Notes',
    icon: Icons.note_outlined,
    summary: 'Write and keep notes on this device',
  ),
  ModuleDefinition(
    id: 'calculator',
    title: 'Calculator',
    icon: Icons.calculate_outlined,
    summary: 'Arithmetic with keyboard and mouse support',
  ),
  ModuleDefinition(
    id: 'clock',
    title: 'Clock',
    icon: Icons.schedule_outlined,
    summary: 'World clock, stopwatch and timer',
  ),
  ModuleDefinition(
    id: 'settings',
    title: 'Settings',
    icon: Icons.tune_outlined,
    summary: 'Themes, accent colours, wallpapers and dock behaviour',
  ),
  ModuleDefinition(
    id: 'device',
    title: 'Device',
    icon: Icons.phone_android_outlined,
    summary: 'Public Android device information and About',
  ),
];

/// Looks up a module by id.
ModuleDefinition moduleById(String id) {
  return kModules.firstWhere(
    (module) => module.id == id,
    orElse: () => kModules.first,
  );
}

/// True when [id] refers to a known module.
bool isKnownModule(String id) => kModules.any((module) => module.id == id);
