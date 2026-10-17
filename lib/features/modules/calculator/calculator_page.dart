import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/calculator_engine.dart';
import 'calculator_keypad.dart';

/// State of the calculator: the expression, the last result and the history.
class CalculatorState {
  const CalculatorState({this.expression = '', this.result = '', this.history = const <String>[]});

  final String expression;
  final String result;
  final List<String> history;

  CalculatorState copyWith({String? expression, String? result, List<String>? history}) {
    return CalculatorState(
      expression: expression ?? this.expression,
      result: result ?? this.result,
      history: history ?? this.history,
    );
  }
}

/// Holds the calculator state and evaluates expressions on demand.
class CalculatorNotifier extends Notifier<CalculatorState> {
  @override
  CalculatorState build() => const CalculatorState();

  void input(String token) {
    final expression = state.expression + token;
    state = state.copyWith(expression: expression, result: '');
  }

  void clear() => state = const CalculatorState();

  void backspace() {
    if (state.expression.isEmpty) return;
    state = state.copyWith(expression: state.expression.substring(0, state.expression.length - 1));
  }

  void negate() {
    final expression = state.expression;
    if (expression.isEmpty) return;
    state = state.copyWith(
      expression: expression.startsWith('-') ? expression.substring(1) : '-$expression',
    );
  }

  /// Evaluates the current expression and records it in the history.
  void evaluate() {
    final expression = state.expression.trim();
    if (expression.isEmpty) return;
    final value = CalculatorEngine.evaluate(expression);
    if (value == null) {
      state = state.copyWith(result: 'Error');
      return;
    }
    final formatted = CalculatorEngine.format(value);
    state = state.copyWith(
      expression: formatted,
      result: formatted,
      history: <String>['$expression = $formatted', ...state.history].take(20).toList(),
    );
  }

  /// Applies a key press coming from a physical keyboard.
  void handleKey(LogicalKeyboardKey key) {
    final character = key.keyLabel;
    if (RegExp(r'^[0-9]$').hasMatch(character)) {
      input(character);
    } else if (character == '+' || character == '-' || character == '*' || character == '/' || character == '%' || character == '^' || character == '(' || character == ')') {
      input(character);
    } else if (character == '.') {
      input('.');
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter || character == '=') {
      evaluate();
    } else if (key == LogicalKeyboardKey.backspace) {
      backspace();
    } else if (key == LogicalKeyboardKey.escape) {
      clear();
    }
  }
}

/// Calculator state.
final calculatorProvider = NotifierProvider<CalculatorNotifier, CalculatorState>(CalculatorNotifier.new);

/// Calculator module with on-screen keys and keyboard input.
class CalculatorPage extends ConsumerStatefulWidget {
  const CalculatorPage({super.key});

  @override
  ConsumerState<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends ConsumerState<CalculatorPage> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'CalculatorKeypad');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calculatorProvider);
    final notifier = ref.read(calculatorProvider.notifier);
    final theme = Theme.of(context);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        notifier.handleKey(event.logicalKey);
      },
      // The keypad scrolls when the window is smaller than its natural size.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.bottomRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      SingleChildScrollView(
                        reverse: true,
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          state.expression.isEmpty ? '0' : state.expression,
                          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.result.isEmpty ? ' ' : '= ${state.result}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                CalculatorKeypad(
                  onToken: notifier.input,
                  onEquals: notifier.evaluate,
                  onClear: notifier.clear,
                  onBackspace: notifier.backspace,
                  onNegate: notifier.negate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
