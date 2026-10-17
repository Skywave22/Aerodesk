import 'package:flutter/material.dart';

import '../../core/widgets/section_header.dart';
import 'about_section.dart';
import 'appearance_section.dart';
import 'behaviour_section.dart';

/// Settings page: appearance, behaviour, shortcuts and about.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: const <Widget>[
        AppearanceSection(),
        Divider(height: 32),
        BehaviourSection(),
        Divider(height: 32),
        _ShortcutsSection(),
        Divider(height: 32),
        SectionHeader(title: 'About', icon: Icons.info_outline),
        AboutSection(),
      ],
    );
  }
}

/// Documents the keyboard shortcuts supported by the shell.
class _ShortcutsSection extends StatelessWidget {
  const _ShortcutsSection();

  static const List<(String, String)> _shortcuts = <(String, String)>[
    ('Ctrl + 1…4', 'Switch workspace'),
    ('Ctrl + [ / ]', 'Previous / next workspace'),
    ('Ctrl + M', 'Minimise the focused window'),
    ('Ctrl + W', 'Close the focused window'),
    ('Escape', 'Close the focused window'),
    ('F11', 'Maximise or restore the focused window'),
    ('Digits, + - * / % ^ ( )', 'Calculator input'),
    ('Enter', 'Calculate'),
    ('Backspace / Escape', 'Calculator: delete / clear'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Keyboard and mouse', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final shortcut in _shortcuts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 168,
                  child: Text(shortcut.$1, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                ),
                Expanded(child: Text(shortcut.$2, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Right-click the desktop, an icon or a window title bar for context menus.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
