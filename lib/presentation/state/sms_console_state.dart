import 'package:flutter/material.dart';
import 'package:sms_console/domain/models/cost_breakdown.dart';
import 'package:sms_console/domain/models/sms_message.dart';

import '../../core/utils/dev_server_mode.dart';

enum SmsConsoleStatus { initial, loading, success, failure }
enum HistoryStatus { initial, loading, loaded, loadingMore, error }
enum CostStatus { initial, loading, loaded, error }
class _Unset {
  const _Unset();
}

const _unset = _Unset();

class SmsConsoleState {
  final String tenantId;
  final String token;
  final DevServerMode serverMode;
  final ThemeMode themeMode;

  // SMS Sending Form State
  final SmsConsoleStatus sendStatus;
  final String? sendErrorMessage;
  final String? lastSentMessageId;

  // Paginated History List State
  final HistoryStatus historyStatus;
  final List<SmsMessage> messages;
  final String? nextCursor;
  final String? historyErrorMessage;

  // Cost Breakdown Analytics State
  final CostStatus costStatus;
  final CostBreakdown? costBreakdown;
  final String? costErrorMessage;

  const SmsConsoleState({
    required this.tenantId,
    required this.token,
    required this.serverMode,
    this.themeMode = ThemeMode.system,
    this.sendStatus = SmsConsoleStatus.initial,
    this.sendErrorMessage,
    this.lastSentMessageId,
    this.historyStatus = HistoryStatus.initial,
    this.messages = const [],
    this.nextCursor,
    this.historyErrorMessage,
    this.costStatus = CostStatus.initial,
    this.costBreakdown,
    this.costErrorMessage,
  });

  SmsConsoleState copyWith({
    String? tenantId,
    String? token,
    DevServerMode? serverMode,
    ThemeMode? themeMode,
    SmsConsoleStatus? sendStatus,
    Object? sendErrorMessage = _unset,
    Object? lastSentMessageId = _unset,
    HistoryStatus? historyStatus,
    List<SmsMessage>? messages,
    Object? nextCursor = _unset,
    Object? historyErrorMessage = _unset,
    CostStatus? costStatus,
    CostBreakdown? costBreakdown,
    Object? costErrorMessage = _unset,
  }) {
    return SmsConsoleState(
      tenantId: tenantId ?? this.tenantId,
      token: token ?? this.token,
      serverMode: serverMode ?? this.serverMode,
      themeMode: themeMode ?? this.themeMode,
      sendStatus: sendStatus ?? this.sendStatus,
      sendErrorMessage: identical(sendErrorMessage, _unset)
          ? this.sendErrorMessage
          : sendErrorMessage as String?,
      lastSentMessageId: identical(lastSentMessageId, _unset)
          ? this.lastSentMessageId
          : lastSentMessageId as String?,
      historyStatus: historyStatus ?? this.historyStatus,
      messages: messages ?? this.messages,
      nextCursor: identical(nextCursor, _unset)
          ? this.nextCursor
          : nextCursor as String?,
      historyErrorMessage: identical(historyErrorMessage, _unset)
          ? this.historyErrorMessage
          : historyErrorMessage as String?,
      costStatus: costStatus ?? this.costStatus,
      costBreakdown: costBreakdown ?? this.costBreakdown,
      costErrorMessage: identical(costErrorMessage, _unset)
          ? this.costErrorMessage
          : costErrorMessage as String?,
    );
  }
}
