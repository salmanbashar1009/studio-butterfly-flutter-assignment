/// A value-type representing an exact monetary amount with up to 4 decimal
/// places, stored as an integer number of base units.
///
/// 1 base unit = 0.0001 of the currency (i.e. 1/10 000th).
///
/// All arithmetic is performed on [int] values — no [double] is ever used
/// for computation or serialisation, preventing IEEE 754 rounding drift on
/// aggregated multi-message invoices.
class Money {
  /// Value in base units (10 000 base units = 1.0000 of the currency).
  final int valueInBaseUnits;
  final String currency;

  const Money({required this.valueInBaseUnits, this.currency = 'EUR'});

  // ---------------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------------

  /// Parses a decimal string such as `"0.0079"` or `"12.4500"` into exact
  /// integer base units without ever going through a [double].
  factory Money.fromDecimalString(String decimal, [String currency = 'EUR']) {
    final trimmed = decimal.trim();
    final isNegative = trimmed.startsWith('-');
    final absolute = isNegative ? trimmed.substring(1) : trimmed;

    final parts = absolute.split('.');
    final intPart = int.parse(parts[0]);

    int fractionalBaseUnits = 0;
    if (parts.length > 1) {
      // Normalise to exactly 4 decimal digits.
      String fractionStr = parts[1];
      if (fractionStr.length > 4) {
        fractionStr = fractionStr.substring(0, 4); // truncate, never round up
      } else {
        fractionStr = fractionStr.padRight(4, '0');
      }
      fractionalBaseUnits = int.parse(fractionStr);
    }

    final baseUnits = intPart * 10000 + fractionalBaseUnits;
    return Money(
      valueInBaseUnits: isNegative ? -baseUnits : baseUnits,
      currency: currency,
    );
  }

  factory Money.zero([String currency = 'EUR']) =>
      Money(valueInBaseUnits: 0, currency: currency);

  // ---------------------------------------------------------------------------
  // Arithmetic
  // ---------------------------------------------------------------------------

  Money operator +(Money other) {
    assert(
      currency == other.currency,
      'Cannot add different currencies: $currency and ${other.currency}',
    );
    return Money(
      valueInBaseUnits: valueInBaseUnits + other.valueInBaseUnits,
      currency: currency,
    );
  }

  Money operator *(int count) {
    return Money(
      valueInBaseUnits: valueInBaseUnits * count,
      currency: currency,
    );
  }

  // ---------------------------------------------------------------------------
  // Serialisation — pure integer arithmetic, no double
  // ---------------------------------------------------------------------------

  /// Returns a 4-decimal-place decimal string such as `"0.0079"` or
  /// `"12.4500"`, using only integer arithmetic.
  String toDecimalString() {
    final isNeg = valueInBaseUnits < 0;
    final abs = valueInBaseUnits.abs();
    final whole = abs ~/ 10000;
    final fraction = (abs % 10000).toString().padLeft(4, '0');
    return '${isNeg ? '-' : ''}$whole.$fraction';
  }

  // ---------------------------------------------------------------------------
  // Display — pure integer arithmetic, no double
  // ---------------------------------------------------------------------------

  /// Returns a human-readable string such as `"€12.45"` or `"€0.0079"`.
  ///
  /// Uses 2 decimal places when the sub-cent digits are both zero (common for
  /// aggregate totals), and 4 decimal places otherwise (per-message rates).
  String format() {
    final symbol = _getSymbol(currency);
    final isNeg = valueInBaseUnits < 0;
    final abs = valueInBaseUnits.abs();
    final whole = abs ~/ 10000;
    final fractionRaw = abs % 10000;

    final String fraction;
    if (fractionRaw % 100 == 0) {
      // e.g. 12.4500 → show "12.45"
      fraction = (fractionRaw ~/ 100).toString().padLeft(2, '0');
    } else {
      // e.g. 0.0079 → show "0.0079"
      fraction = fractionRaw.toString().padLeft(4, '0');
    }

    return '${isNeg ? '-' : ''}$symbol$whole.$fraction';
  }

  // ---------------------------------------------------------------------------
  // Utility (for interop with non-financial display, e.g. charts)
  // ---------------------------------------------------------------------------

  /// Returns a [double] approximation. **Do not use for arithmetic or
  /// serialisation** — use [toDecimalString] instead.
  double toDouble() => valueInBaseUnits / 10000.0;

  // ---------------------------------------------------------------------------
  // Object overrides
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          valueInBaseUnits == other.valueInBaseUnits &&
          currency == other.currency;

  @override
  int get hashCode => valueInBaseUnits.hashCode ^ currency.hashCode;

  @override
  String toString() => '$currency ${toDecimalString()}';

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _getSymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      default:
        return '$currencyCode ';
    }
  }
}
