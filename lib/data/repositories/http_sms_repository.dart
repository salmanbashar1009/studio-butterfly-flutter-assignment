import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sms_console/domain/models/cost_breakdown.dart';
import 'package:sms_console/domain/models/paginated_messages.dart';
import 'package:sms_console/domain/models/sms_exceptions.dart';
import 'package:sms_console/domain/models/sms_send_response.dart';
import 'package:sms_console/domain/repositories/sms_repository.dart';

class HttpSmsRepository implements SmsRepository {
  final String baseUrl;
  final http.Client _client;

  HttpSmsRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> _headers(String tenantId, String token) {
    return {
      'Authorization': 'Bearer $token',
      'X-Tenant-Id': tenantId,
      'Content-Type': 'application/json',
    };
  }

  void _handleErrorResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw SmsAuthenticationException('Authentication token has expired or is invalid (HTTP ${response.statusCode}).');
    } else if (response.statusCode == 429) {
      final retryAfter = int.tryParse(response.headers['retry-after'] ?? '');
      throw SmsRateLimitException(
        retryAfterSeconds: retryAfter,
        message: 'Rate limit exceeded. Please wait ${retryAfter ?? 5} seconds and try again.',
      );
    } else if (response.statusCode == 502) {
      throw SmsUpstreamException('The upstream SMS gateway provider failed (HTTP 502).');
    } else if (response.statusCode >= 500) {
      throw SmsServerException('Internal server error occurred on the SMS gateway (HTTP ${response.statusCode}).');
    } else if (response.statusCode == 400) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw SmsValidationException(
          body['errorCode'] as String? ?? 'BAD_REQUEST',
          body['message'] as String? ?? 'Validation error.',
        );
      } catch (_) {
        throw SmsException('Invalid request parameters (HTTP 400).');
      }
    } else {
      throw SmsException('An unexpected error occurred (HTTP ${response.statusCode}).');
    }
  }

  @override
  Future<SmsSendResponse> sendSms({
    required String tenantId,
    required String token,
    required String to,
    required String body,
    String? referenceId,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/sms/send');
    final payload = {
      'to': to,
      'body': body,
      if (referenceId != null) 'referenceId': referenceId,
    };

    try {
      final response = await _client
          .post(
            url,
            headers: _headers(tenantId, token),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 202 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SmsSendResponse.fromJson(data);
      } else {
        _handleErrorResponse(response);
        throw SmsException('Failed to send SMS');
      }
    } on http.ClientException catch (e) {
      throw SmsNetworkException('Network communication failed: ${e.message}');
    } on TimeoutException {
      throw SmsNetworkException('Request timed out. Please check your connection speed.');
    }
  }

  @override
  Future<void> sendBulk({
    required String tenantId,
    required String token,
    required List<Map<String, String>> messages,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/sms/bulk');
    final payload = {'messages': messages};

    try {
      final response = await _client
          .post(
            url,
            headers: _headers(tenantId, token),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 207 || response.statusCode == 200) {
        return;
      } else {
        _handleErrorResponse(response);
      }
    } on http.ClientException catch (e) {
      throw SmsNetworkException('Network communication failed: ${e.message}');
    } on TimeoutException {
      throw SmsNetworkException('Bulk request timed out.');
    }
  }

  @override
  Future<CostBreakdown> getCostBreakdown({
    required String tenantId,
    required String token,
    required DateTime from,
    required DateTime to,
  }) async {
    final url = Uri.parse('$baseUrl/api/v1/sms/cost/breakdown'
        '?from=${from.toIso8601String()}&to=${to.toIso8601String()}');

    try {
      final response = await _client
          .get(
            url,
            headers: _headers(tenantId, token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CostBreakdown.fromJson(data);
      } else {
        _handleErrorResponse(response);
        throw SmsException('Failed to get cost breakdown');
      }
    } on http.ClientException catch (e) {
      throw SmsNetworkException('Network communication failed: ${e.message}');
    } on TimeoutException {
      throw SmsNetworkException('Request timed out. Please check your connection speed.');
    }
  }

  @override
  Future<PaginatedMessages> getMessages({
    required String tenantId,
    required String token,
    String? cursor,
    int limit = 50,
  }) async {
    final cursorQuery = cursor != null ? '&cursor=$cursor' : '';
    final url = Uri.parse('$baseUrl/api/v1/sms/messages?limit=$limit$cursorQuery');

    try {
      final response = await _client
          .get(
            url,
            headers: _headers(tenantId, token),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginatedMessages.fromJson(data);
      } else {
        _handleErrorResponse(response);
        throw SmsException('Failed to get messages');
      }
    } on http.ClientException catch (e) {
      throw SmsNetworkException('Network communication failed: ${e.message}');
    } on TimeoutException {
      throw SmsNetworkException('Request timed out. Please check your connection speed.');
    }
  }
}
