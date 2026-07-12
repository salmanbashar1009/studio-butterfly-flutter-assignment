import 'package:sms_console/domain/models/sms_status.dart';

import '../../core/utils/money.dart';

class SmsMessage {
  final String messageId;
  final String recipient; // Dynamic, arrives pre-masked from the server
  final SmsStatus status;
  final int segmentCount;
  final Money cost;
  final DateTime sentAt;
  final String
  provider; // Added to store the actual provider instead of inferring it

  SmsMessage({
    required this.messageId,
    required this.recipient,
    required this.status,
    required this.segmentCount,
    required this.cost,
    required this.sentAt,
    required this.provider,
  });

  factory SmsMessage.fromJson(
    Map<String, dynamic> json, [
    String defaultCurrency = 'EUR',
  ]) {
    return SmsMessage(
      messageId: json['messageId'] as String,
      recipient: json['recipient'] as String,
      status: SmsStatus.fromString(json['status'] as String),
      segmentCount: json['segmentCount'] as int? ?? 1,
      cost: Money.fromDecimalString(json['cost'] as String, defaultCurrency),
      sentAt: DateTime.parse(json['sentAt'] as String),
      provider: json['provider'] as String? ?? 'UNKNOWN',
    );
  }
}
