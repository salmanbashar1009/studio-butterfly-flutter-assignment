import 'package:flutter_test/flutter_test.dart';
import 'package:sms_console/core/utils/money.dart';

void main() {
  group('Money Parsing & Base Units Tests', () {
    test('Should parse precise 4-decimal rate string accurately', () {
      final money = Money.fromDecimalString('0.0079', 'EUR');
      expect(money.valueInBaseUnits, equals(79));
      expect(money.currency, equals('EUR'));
    });

    test('Should parse 2-decimal cost string accurately', () {
      final money = Money.fromDecimalString('12.4500', 'EUR');
      expect(money.valueInBaseUnits, equals(124500));
    });

    test('Should parse integer string accurately', () {
      final money = Money.fromDecimalString('8', 'USD');
      expect(money.valueInBaseUnits, equals(80000));
      expect(money.currency, equals('USD'));
    });

    test('Should parse shorthand decimal correctly', () {
      final money = Money.fromDecimalString('0.15', 'EUR');
      expect(money.valueInBaseUnits, equals(1500));
    });
  });

  group('Money Operations Arithmetic', () {
    test('Should add two money values of the same currency without drift', () {
      final a = Money.fromDecimalString('0.0079', 'EUR');
      final b = Money.fromDecimalString('0.1500', 'EUR');
      final sum = a + b;
      
      expect(sum.valueInBaseUnits, equals(1579)); // 79 + 1500
      expect(sum.toDecimalString(), equals('0.1579'));
    });

    test('Should multiply money by segment count exactly', () {
      final rate = Money.fromDecimalString('0.0079', 'EUR');
      final total = rate * 3;

      expect(total.valueInBaseUnits, equals(237));
      expect(total.toDecimalString(), equals('0.0237'));
    });

    test('Should throw assertion error if adding different currencies', () {
      final eur = Money.fromDecimalString('1.0000', 'EUR');
      final usd = Money.fromDecimalString('1.0000', 'USD');
      
      expect(() => eur + usd, throwsA(isA<AssertionError>()));
    });
  });

  group('Money String Formatting', () {
    test('Should format with currency symbol EUR', () {
      final money = Money.fromDecimalString('12.4500', 'EUR');
      expect(money.format(), equals('€12.45'));
    });

    test('Should format with currency symbol USD', () {
      final money = Money.fromDecimalString('8.0079', 'USD');
      expect(money.format(), equals('\$8.0079'));
    });

    test('Should format default case with text code', () {
      final money = Money.fromDecimalString('100.0000', 'CAD');
      expect(money.format(), equals('CAD 100.00'));
    });
  });
}
