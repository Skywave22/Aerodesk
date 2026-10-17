import 'package:flutter/material.dart';

import '../../theme/accent_colors.dart';

/// Horizontal picker for the accent colour.
class AccentPicker extends StatelessWidget {
  const AccentPicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: AccentColorOption.options.map((option) {
        final selected = option.id == selectedId;
        return Semantics(
          label: '${option.name} accent',
          selected: selected,
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onSelected(option.id),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: selected ? 44 : 34,
                  height: selected ? 44 : 34,
                  decoration: BoxDecoration(
                    color: option.seed,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? theme.colorScheme.onSurface : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 20, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
