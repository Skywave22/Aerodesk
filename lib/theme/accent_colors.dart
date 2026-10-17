import 'package:flutter/material.dart';

/// A selectable accent colour used by the AeroDesk design system.
class AccentColorOption {
  const AccentColorOption({
    required this.id,
    required this.name,
    required this.seed,
  });

  final String id;
  final String name;
  final Color seed;

  /// Every accent offered in Settings -> Appearance.
  static const List<AccentColorOption> options = <AccentColorOption>[
    AccentColorOption(id: 'sky', name: 'Sky', seed: Color(0xFF0B84FF)),
    AccentColorOption(id: 'teal', name: 'Teal', seed: Color(0xFF00A39A)),
    AccentColorOption(id: 'violet', name: 'Violet', seed: Color(0xFF7C5CFF)),
    AccentColorOption(id: 'amber', name: 'Amber', seed: Color(0xFFF59E0B)),
    AccentColorOption(id: 'rose', name: 'Rose', seed: Color(0xFFF43F5E)),
    AccentColorOption(id: 'emerald', name: 'Emerald', seed: Color(0xFF10B981)),
    AccentColorOption(id: 'graphite', name: 'Graphite', seed: Color(0xFF64748B)),
  ];

  static AccentColorOption byId(String id) {
    return options.firstWhere(
      (option) => option.id == id,
      orElse: () => options.first,
    );
  }
}
