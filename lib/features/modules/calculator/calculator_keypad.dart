import 'package:flutter/material.dart';

/// On-screen keypad of the calculator.
class CalculatorKeypad extends StatelessWidget {
  const CalculatorKeypad({
    super.key,
    required this.onToken,
    required this.onEquals,
    required this.onClear,
    required this.onBackspace,
    required this.onNegate,
  });

  final ValueChanged<String> onToken;
  final VoidCallback onEquals;
  final VoidCallback onClear;
  final VoidCallback onBackspace;
  final VoidCallback onNegate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = <_Key>[
      _Key('C', _KeyStyle.action, onClear),
      _Key('( )', _KeyStyle.action, () => onToken('(')),
      _Key('%', _KeyStyle.action, () => onToken('%')),
      _Key('÷', _KeyStyle.operator, () => onToken('/')),
      _Key('7', _KeyStyle.digit, () => onToken('7')),
      _Key('8', _KeyStyle.digit, () => onToken('8')),
      _Key('9', _KeyStyle.digit, () => onToken('9')),
      _Key('×', _KeyStyle.operator, () => onToken('*')),
      _Key('4', _KeyStyle.digit, () => onToken('4')),
      _Key('5', _KeyStyle.digit, () => onToken('5')),
      _Key('6', _KeyStyle.digit, () => onToken('6')),
      _Key('−', _KeyStyle.operator, () => onToken('-')),
      _Key('1', _KeyStyle.digit, () => onToken('1')),
      _Key('2', _KeyStyle.digit, () => onToken('2')),
      _Key('3', _KeyStyle.digit, () => onToken('3')),
      _Key('+', _KeyStyle.operator, () => onToken('+')),
      _Key('±', _KeyStyle.action, onNegate),
      _Key('0', _KeyStyle.digit, () => onToken('0')),
      _Key('.', _KeyStyle.digit, () => onToken('.')),
      _Key('=', _KeyStyle.equals, onEquals),
      _Key('⌫', _KeyStyle.action, onBackspace),
      _Key('^', _KeyStyle.operator, () => onToken('^')),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: keys.map((entry) => _KeyButton(keyData: entry, theme: theme)).toList(),
      ),
    );
  }
}

enum _KeyStyle { digit, operator, action, equals }

class _Key {
  const _Key(this.label, this.style, this.onPressed);

  final String label;
  final _KeyStyle style;
  final VoidCallback onPressed;
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.keyData, required this.theme});

  final _Key keyData;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final background = switch (keyData.style) {
      _KeyStyle.digit => theme.colorScheme.surfaceContainerHigh,
      _KeyStyle.operator => theme.colorScheme.secondaryContainer,
      _KeyStyle.action => theme.colorScheme.surfaceContainerHighest,
      _KeyStyle.equals => theme.colorScheme.primary,
    };
    final foreground = switch (keyData.style) {
      _KeyStyle.equals => theme.colorScheme.onPrimary,
      _KeyStyle.operator => theme.colorScheme.onSecondaryContainer,
      _ => theme.colorScheme.onSurface,
    };
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: keyData.onPressed,
        child: Center(
          child: Text(
            keyData.label,
            style: theme.textTheme.titleMedium?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
