import '../../core/utils/money.dart';

class CostRow {
  final String provider;
  final Money totalCost;
  final int messageCount;

  CostRow({
    required this.provider,
    required this.totalCost,
    required this.messageCount,
  });

  factory CostRow.fromJson(Map<String, dynamic> json, String currency) {
    return CostRow(
      provider: json['provider'] as String,
      totalCost: Money.fromDecimalString(json['totalCost'] as String, currency),
      messageCount: json['messageCount'] as int? ?? 0,
    );
  }
}
