import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:sms_console/domain/models/cost_breakdown.dart';
import 'package:sms_console/domain/models/cost_row.dart';
import 'package:sms_console/domain/models/paginated_messages.dart';
import 'package:sms_console/domain/models/sms_exceptions.dart';
import 'package:sms_console/domain/models/sms_message.dart';
import 'package:sms_console/domain/models/sms_send_response.dart';
import 'package:sms_console/domain/models/sms_status.dart';
import 'package:sms_console/domain/repositories/sms_repository.dart';

import '../../core/utils/dev_server_mode.dart';
import '../../core/utils/money.dart';


class FakeSmsRepository implements SmsRepository {
  DevServerMode mode = DevServerMode.success;
  int latencyMs = 600;

  // Tenant-isolated in-memory database.
  final Map<String, List<SmsMessage>> _tenantMessages = {};

  // Tracks in-flight status-transition timers so they can be cancelled
  // (e.g. in test tearDown) instead of leaking past widget/test disposal.
  final List<Timer> _pendingTimers = [];

  FakeSmsRepository() {
    _initTenantData('9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f');
    _initTenantData('tenant-usd-uuid-12345');
  }

  void _initTenantData(String tenantId) {
    // Start empty to demonstrate the 'Empty State' UI on first load.
    _tenantMessages[tenantId] = [];
  }

  void clearAllData() {
    _tenantMessages.clear();
    _initTenantData('9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f');
    _initTenantData('tenant-usd-uuid-12345');
  }

  /// Cancels all pending status-transition timers (the 3s "sent" and
  /// 6s "delivered/failed" simulations from [sendSms]). Call this in test
  /// tearDown to prevent "A Timer is still pending" assertion failures
  /// when a widget/test tree is disposed before those timers fire.
  void dispose() {
    for (final t in _pendingTimers) {
      t.cancel();
    }
    _pendingTimers.clear();
  }

  /// Validates authentication (401) and authorisation (403) per API contract.
  void _checkAuth(String tenantId, String token) {
    if (token.isEmpty || token == 'expired' || token == 'invalid') {
      throw SmsAuthenticationException(
        'The provided authentication token is invalid or has expired.',
      );
    }

    // Map known tokens → tenants to enforce strict isolation.
    const tokenToTenant = {
      'dummy_token_eur': '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
      'dev_mock_token_12345': '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
      'dummy_token_usd': 'tenant-usd-uuid-12345',
    };

    if (tokenToTenant.containsKey(token) && tokenToTenant[token] != tenantId) {
      throw SmsForbiddenException(
        'X-Tenant-Id mismatch. This token is not authorised for the requested tenant.',
      );
    }
  }

  Future<void> _simulateNetwork() async {
    await Future.delayed(Duration(milliseconds: latencyMs));
    switch (mode) {
      case DevServerMode.success:
      case DevServerMode.empty:
        return;
      case DevServerMode.networkFailure:
        throw SmsNetworkException('No internet connection. Please verify your connection.');
      case DevServerMode.timeout:
        throw SmsNetworkException('Connection timeout. The server took too long to respond.');
      case DevServerMode.serverError:
        throw SmsUpstreamException(
          'The upstream SMS provider gateway failed to respond (HTTP 502).',
        );
      case DevServerMode.rateLimit429:
        throw SmsRateLimitException(
          retryAfterSeconds: 5,
          message: 'Rate limit exceeded. Try again in 5 seconds.',
        );
    }
  }

  String _generateMessageId() {
    final random = math.Random();
    final id =
    List.generate(8, (_) => random.nextInt(16).toRadixString(16)).join();
    return 'SM$id';
  }

  @override
  Future<SmsSendResponse> sendSms({
    required String tenantId,
    required String token,
    required String to,
    required String body,
    String? referenceId,
  }) async {
    _checkAuth(tenantId, token);
    await _simulateNetwork();

    final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(to)) {
      throw SmsValidationException(
        'INVALID_PHONE_NUMBER',
        'Phone number must be E.164 compliant (e.g. +4915112345678).',
      );
    }

    final currency = tenantId == 'tenant-usd-uuid-12345' ? 'USD' : 'EUR';

    final provider = body.toLowerCase().contains('aws')
        ? 'AWS_SNS'
        : (body.toLowerCase().contains('vonage') ? 'VONAGE' : 'TWILIO');

    final int segmentCount = (body.length / 160).ceil().clamp(1, 999);

    // All rates stored as exact decimal strings — no double arithmetic.
    final Money rate = provider == 'AWS_SNS'
        ? Money.fromDecimalString('0.0460', currency)
        : (provider == 'VONAGE'
        ? Money.fromDecimalString('0.0650', currency)
        : Money.fromDecimalString('0.0750', currency));

    final cost = rate * segmentCount;

    final messageId = _generateMessageId();

    final response = SmsSendResponse(
      messageId: messageId,
      provider: provider,
      status: SmsStatus.accepted,
      segmentCount: segmentCount,
      cost: cost,
    );

    _tenantMessages.putIfAbsent(tenantId, () => []);

    // Mask phone number as per contract (do not store or log the raw number).
    final masked = to.length > 7
        ? '${to.substring(0, 6)}*****${to.substring(to.length - 2)}'
        : to;

    final newMessage = SmsMessage(
      messageId: messageId,
      recipient: masked,
      status: SmsStatus.accepted,
      segmentCount: segmentCount,
      cost: cost,
      sentAt: DateTime.now(),
      provider: provider,
    );

    _tenantMessages[tenantId]!.insert(0, newMessage);

    // Simulate asynchronous delivery status transitions.
    _startStatusTransition(tenantId, messageId);

    return response;
  }

  @override
  Future<void> sendBulk({
    required String tenantId,
    required String token,
    required List<Map<String, String>> messages,
  }) async {
    _checkAuth(tenantId, token);
    await _simulateNetwork();
    for (final msg in messages) {
      await sendSms(
        tenantId: tenantId,
        token: token,
        to: msg['to'] ?? '',
        body: msg['body'] ?? '',
      );
    }
  }

  void _startStatusTransition(String tenantId, String messageId) {
    _pendingTimers.add(
      Timer(
        const Duration(seconds: 3),
            () => _updateStatus(tenantId, messageId, SmsStatus.sent),
      ),
    );
    _pendingTimers.add(
      Timer(const Duration(seconds: 6), () {
        final list = _tenantMessages[tenantId];
        if (list == null) return;
        final idx = list.indexWhere((m) => m.messageId == messageId);
        if (idx == -1) return;
        final old = list[idx];
        final finalStatus =
        old.recipient.contains('404') ? SmsStatus.failed : SmsStatus.delivered;
        _updateStatus(tenantId, messageId, finalStatus);
      }),
    );
  }

  void _updateStatus(String tenantId, String messageId, SmsStatus newStatus) {
    final list = _tenantMessages[tenantId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.messageId == messageId);
    if (idx == -1) return;
    final old = list[idx];
    list[idx] = SmsMessage(
      messageId: old.messageId,
      recipient: old.recipient,
      status: newStatus,
      segmentCount: old.segmentCount,
      cost: old.cost,
      sentAt: old.sentAt,
      provider: old.provider,
    );
  }

  @override
  Future<CostBreakdown> getCostBreakdown({
    required String tenantId,
    required String token,
    required DateTime from,
    required DateTime to,
  }) async {
    _checkAuth(tenantId, token);
    await _simulateNetwork();

    final currency = tenantId == 'tenant-usd-uuid-12345' ? 'USD' : 'EUR';

    if (mode == DevServerMode.empty) {
      return CostBreakdown(
        currency: currency,
        totalCost: Money.zero(currency),
        rows: [],
      );
    }

    final messages = _tenantMessages[tenantId] ?? [];
    final Map<String, Money> providerCosts = {};
    final Map<String, int> providerCounts = {};

    for (final msg in messages) {
      if (msg.sentAt.isAfter(from) && msg.sentAt.isBefore(to)) {
        final provider = msg.provider;
        providerCosts[provider] =
            (providerCosts[provider] ?? Money.zero(currency)) + msg.cost;
        providerCounts[provider] = (providerCounts[provider] ?? 0) + 1;
      }
    }

    final List<CostRow> rows = [];
    Money totalCost = Money.zero(currency);
    providerCosts.forEach((provider, cost) {
      rows.add(CostRow(
        provider: provider,
        totalCost: cost,
        messageCount: providerCounts[provider]!,
      ));
      totalCost = totalCost + cost;
    });

    return CostBreakdown(currency: currency, totalCost: totalCost, rows: rows);
  }

  @override
  Future<PaginatedMessages> getMessages({
    required String tenantId,
    required String token,
    String? cursor,
    int limit = 50,
  }) async {
    _checkAuth(tenantId, token);
    await _simulateNetwork();

    if (mode == DevServerMode.empty) {
      return PaginatedMessages(items: [], nextCursor: null);
    }

    final messages = _tenantMessages[tenantId] ?? [];

    int offset = 0;
    if (cursor != null) {
      try {
        final decoded = jsonDecode(utf8.decode(base64.decode(cursor)));
        offset = (decoded as Map<String, dynamic>)['offset'] as int? ?? 0;
      } catch (_) {
        offset = 0;
      }
    }

    // Defensive clamping
    offset = offset.clamp(0, messages.length);
    final end = (offset + limit).clamp(offset, messages.length);

    final sliced = messages.sublist(offset, end);

    final hasNext = end < messages.length;
    final nextCursor = hasNext
        ? base64.encode(utf8.encode(jsonEncode({'offset': end})))
        : null;

    print('DEBUG getMessages - cursor: $cursor | offset: $offset | total messages: ${messages.length} | limit: $limit');

    return PaginatedMessages(items: sliced, nextCursor: nextCursor);
  }

  List<SmsMessage> getTenantMessagesForTest(String tenantId) {
    return _tenantMessages.putIfAbsent(tenantId, () => []);
  }
}