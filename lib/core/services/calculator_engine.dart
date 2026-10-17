import 'dart:math' as math;

/// A small dependency-free arithmetic evaluator used by the Calculator module.
///
/// Supports `+ - * / %`, the power operator `^` (right-associative),
/// parentheses and unary signs.
class CalculatorEngine {
  const CalculatorEngine._();

  /// Evaluates [expression], returning null when it cannot be parsed.
  static double? evaluate(String expression) {
    final trimmed = expression.trim();
    if (trimmed.isEmpty) return null;
    try {
      return _ExpressionParser(trimmed).parse();
    } on FormatException {
      return null;
    }
  }

  /// Formats a result for display.
  static String format(double value) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toInt().toString();
    }
    var text = value.toStringAsFixed(9);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
    }
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }
}

class _ExpressionParser {
  _ExpressionParser(this._input);

  final String _input;
  int _pos = 0;

  double parse() {
    final value = _parseSum();
    _skipWhitespace();
    if (_pos != _input.length) throw const FormatException('Unexpected input');
    return value;
  }

  double _parseSum() {
    var value = _parseProduct();
    while (true) {
      _skipWhitespace();
      if (_pos >= _input.length) break;
      final operator = _input[_pos];
      if (operator != '+' && operator != '-') break;
      _pos++;
      final operand = _parseProduct();
      value = operator == '+' ? value + operand : value - operand;
    }
    return value;
  }

  double _parseProduct() {
    var value = _parsePower();
    while (true) {
      _skipWhitespace();
      if (_pos >= _input.length) break;
      final operator = _input[_pos];
      if (operator != '*' && operator != '/' && operator != '%') break;
      _pos++;
      final operand = _parsePower();
      if (operator == '*') {
        value *= operand;
      } else if (operator == '/') {
        if (operand == 0) throw const FormatException('Division by zero');
        value /= operand;
      } else {
        if (operand == 0) throw const FormatException('Modulo by zero');
        value %= operand;
      }
    }
    return value;
  }

  double _parsePower() {
    final base = _parseUnary();
    _skipWhitespace();
    if (_pos < _input.length && _input[_pos] == '^') {
      _pos++;
      final exponent = _parsePower();
      return math.pow(base, exponent).toDouble();
    }
    return base;
  }

  double _parseUnary() {
    _skipWhitespace();
    if (_pos < _input.length && (_input[_pos] == '-' || _input[_pos] == '+')) {
      final operator = _input[_pos];
      _pos++;
      final value = _parseUnary();
      return operator == '-' ? -value : value;
    }
    return _parsePrimary();
  }

  double _parsePrimary() {
    _skipWhitespace();
    if (_pos >= _input.length) throw const FormatException('Unexpected end of expression');
    final char = _input[_pos];
    if (char == '(') {
      _pos++;
      final value = _parseSum();
      _skipWhitespace();
      if (_pos >= _input.length || _input[_pos] != ')') {
        throw const FormatException('Missing closing parenthesis');
      }
      _pos++;
      return value;
    }
    if (RegExp(r'[0-9]').hasMatch(char) || char == '.') {
      final start = _pos;
      var seenDot = false;
      while (_pos < _input.length) {
        final current = _input[_pos];
        if (current == '.') {
          if (seenDot) break;
          seenDot = true;
        } else if (!RegExp(r'[0-9]').hasMatch(current)) {
          break;
        }
        _pos++;
      }
      final value = double.tryParse(_input.substring(start, _pos));
      if (value == null) throw const FormatException('Invalid number');
      return value;
    }
    throw const FormatException('Unexpected character');
  }

  void _skipWhitespace() {
    while (_pos < _input.length && _input[_pos] == ' ') {
      _pos++;
    }
  }
}
