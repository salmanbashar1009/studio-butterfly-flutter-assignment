import 'package:sms_console/domain/models/sms_status.dart';

import '../../core/utils/money.dart';

class SmsSendResponse {
  final String messageId;
  final String provider;
  final SmsStatus status;
  final int segmentCount;
  final Money cost;

  SmsSendResponse({
    required this.messageId,
    required this.provider,
    required this.status,
    required this.segmentCount,
    required this.cost,
  });

  factory SmsSendResponse.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as String? ?? 'EUR';
    return SmsSendResponse(
      messageId: json['messageId'] as String,
      provider: json['provider'] as String,
      status: SmsStatus.fromString(json['status'] as String),
      segmentCount: json['segmentCount'] as int? ?? 1,
      cost: Money.fromDecimalString(json['cost'] as String, currency),
    );
  }
}
