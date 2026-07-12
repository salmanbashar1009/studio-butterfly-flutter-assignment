import 'package:sms_console/domain/models/cost_row.dart';

import '../../core/utils/money.dart';

class CostBreakdown {
  final String currency;
  final Money totalCost;
  final List<CostRow> rows;

  CostBreakdown({
    required this.currency,
    required this.totalCost,
    required this.rows,
  });

  factory CostBreakdown.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as String? ?? 'EUR';
    final rowsList = (json['rows'] as List<dynamic>? ?? [])
        .map((e) => CostRow.fromJson(e as Map<String, dynamic>, currency))
        .toList();
    return CostBreakdown(
      currency: currency,
      totalCost: Money.fromDecimalString(json['totalCost'] as String, currency),
      rows: rowsList,
    );
  }
}
