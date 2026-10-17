import 'package:aerodesk/core/services/calculator_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorEngine.evaluate', () {
    test('adds, subtracts, multiplies and divides', () {
      expect(CalculatorEngine.evaluate('1+2'), 3);
      expect(CalculatorEngine.evaluate('10 - 4'), 6);
      expect(CalculatorEngine.evaluate('6 * 7'), 42);
      expect(CalculatorEngine.evaluate('9 / 2'), 4.5);
    });

    test('respects operator precedence', () {
      expect(CalculatorEngine.evaluate('2 + 3 * 4'), 14);
      expect(CalculatorEngine.evaluate('(2 + 3) * 4'), 20);
    });

    test('supports unary signs and nested parentheses', () {
      expect(CalculatorEngine.evaluate('-5 + 8'), 3);
      expect(CalculatorEngine.evaluate('-(3 + 4)'), -7);
      expect(CalculatorEngine.evaluate('((1 + 2) * (3 + 4))'), 21);
    });

    test('supports the power operator right-associatively', () {
      expect(CalculatorEngine.evaluate('2 ^ 3 ^ 2'), 512);
      expect(CalculatorEngine.evaluate('4 ^ 0.5'), 2);
    });

    test('supports the modulo operator', () {
      expect(CalculatorEngine.evaluate('17 % 5'), 2);
    });

    test('returns null for invalid input', () {
      expect(CalculatorEngine.evaluate(''), null);
      expect(CalculatorEngine.evaluate('   '), null);
      expect(CalculatorEngine.evaluate('1 +'), null);
      expect(CalculatorEngine.evaluate('(1 + 2'), null);
      expect(CalculatorEngine.evaluate('1 * * 2'), null);
      expect(CalculatorEngine.evaluate('1 / 0'), null);
      expect(CalculatorEngine.evaluate('abc'), null);
    });
  });

  group('CalculatorEngine.format', () {
    test('formats whole numbers without decimals', () {
      expect(CalculatorEngine.format(3), '3');
      expect(CalculatorEngine.format(-12), '-12');
      expect(CalculatorEngine.format(0), '0');
    });

    test('formats fractional numbers without trailing zeros', () {
      expect(CalculatorEngine.format(4.5), '4.5');
      expect(CalculatorEngine.format(1), '1');
      expect(CalculatorEngine.format(0.125), '0.125');
    });

    test('reports errors for non-finite results', () {
      expect(CalculatorEngine.format(double.nan), 'Error');
      expect(CalculatorEngine.format(double.infinity), 'Error');
    });
  });
}
