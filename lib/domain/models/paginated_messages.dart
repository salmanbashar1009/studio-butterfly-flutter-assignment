import 'package:sms_console/domain/models/sms_message.dart';

class PaginatedMessages {
  final List<SmsMessage> items;
  final String? nextCursor;

  PaginatedMessages({
    required this.items,
    this.nextCursor,
  });

  factory PaginatedMessages.fromJson(Map<String, dynamic> json, [String defaultCurrency = 'EUR']) {
    final list = (json['items'] as List<dynamic>? ?? [])
        .map((e) => SmsMessage.fromJson(e as Map<String, dynamic>, defaultCurrency))
        .toList();
    return PaginatedMessages(
      items: list,
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
