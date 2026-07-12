import 'package:sms_console/domain/models/cost_breakdown.dart';
import 'package:sms_console/domain/models/paginated_messages.dart';
import 'package:sms_console/domain/models/sms_send_response.dart';

abstract class SmsRepository {
  Future<SmsSendResponse> sendSms({
    required String tenantId,
    required String token,
    required String to,
    required String body,
    String? referenceId,
  });

  /// Sends multiple messages in a single batch.
  /// Note: body parameter is simplified here for the interface;
  /// a production version would use a list of message objects.
  Future<void> sendBulk({
    required String tenantId,
    required String token,
    required List<Map<String, String>> messages,
  });

  Future<CostBreakdown> getCostBreakdown({
    required String tenantId,
    required String token,
    required DateTime from,
    required DateTime to,
  });

  Future<PaginatedMessages> getMessages({
    required String tenantId,
    required String token,
    String? cursor,
    int limit = 50,
  });
}
