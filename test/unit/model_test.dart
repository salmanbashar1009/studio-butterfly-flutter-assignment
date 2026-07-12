import 'package:flutter_test/flutter_test.dart';
import 'package:sms_console/domain/models/cost_breakdown.dart';
import 'package:sms_console/domain/models/paginated_messages.dart';
import 'package:sms_console/domain/models/sms_send_response.dart';
import 'package:sms_console/domain/models/sms_status.dart';

void main() {
  group('API Model Deserialization Tests', () {
    test('Should parse SmsSendResponse correctly', () {
      final json = {
        'messageId': 'SM3fa85f64',
        'provider': 'TWILIO',
        'status': 'ACCEPTED',
        'segmentCount': 2,
        'cost': '0.1500',
        'currency': 'EUR'
      };

      final response = SmsSendResponse.fromJson(json);

      expect(response.messageId, equals('SM3fa85f64'));
      expect(response.provider, equals('TWILIO'));
      expect(response.status, equals(SmsStatus.accepted));
      expect(response.segmentCount, equals(2));
      expect(response.cost.valueInBaseUnits, equals(1500)); // 0.1500 EUR -> 1500 base units
      expect(response.cost.currency, equals('EUR'));
    });

    test('Should parse CostBreakdown correctly', () {
      final json = {
        'currency': 'EUR',
        'totalCost': '12.4500',
        'rows': [
          {'provider': 'TWILIO', 'totalCost': '8.2500', 'messageCount': 110},
          {'provider': 'AWS_SNS', 'totalCost': '4.2000', 'messageCount': 91}
        ]
      };

      final breakdown = CostBreakdown.fromJson(json);

      expect(breakdown.currency, equals('EUR'));
      expect(breakdown.totalCost.valueInBaseUnits, equals(124500));
      expect(breakdown.rows.length, equals(2));
      expect(breakdown.rows[0].provider, equals('TWILIO'));
      expect(breakdown.rows[0].totalCost.valueInBaseUnits, equals(82500));
      expect(breakdown.rows[0].messageCount, equals(110));
    });

    test('Should parse PaginatedMessages correctly', () {
      final json = {
        'items': [
          {
            'messageId': 'SM3fa85f64',
            'recipient': '+4915*****78',
            'status': 'DELIVERED',
            'segmentCount': 2,
            'cost': '0.1500',
            'sentAt': '2026-07-09T08:14:22Z'
          }
        ],
        'nextCursor': 'eyJvZmZzZXQiOjUwfQ'
      };

      final paginated = PaginatedMessages.fromJson(json, 'EUR');

      expect(paginated.items.length, equals(1));
      expect(paginated.nextCursor, equals('eyJvZmZzZXQiOjUwfQ'));

      final msg = paginated.items[0];
      expect(msg.messageId, equals('SM3fa85f64'));
      expect(msg.recipient, equals('+4915*****78'));
      expect(msg.status, equals(SmsStatus.delivered));
      expect(msg.segmentCount, equals(2));
      expect(msg.cost.valueInBaseUnits, equals(1500));
      expect(msg.sentAt, equals(DateTime.parse('2026-07-09T08:14:22Z')));
    });
  });
}
