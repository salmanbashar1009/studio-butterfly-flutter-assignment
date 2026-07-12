import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_console/domain/repositories/sms_repository.dart';
import 'package:sms_console/data/repositories/fake_sms_repository.dart';
import 'package:sms_console/domain/models/sms_exceptions.dart';
import 'package:sms_console/presentation/state/sms_console_state.dart';

import '../../core/utils/dev_server_mode.dart';

class SmsConsoleCubit extends Cubit<SmsConsoleState> {
  final SmsRepository _repository;

  SmsConsoleCubit({
    required this._repository,
    required String initialTenantId,
    required String initialToken,
  }) : super(
         SmsConsoleState(
           tenantId: initialTenantId,
           token: initialToken,
           serverMode: DevServerMode.success,
         ),
       ) {
    if (_repository is FakeSmsRepository) {
      _repository.mode = DevServerMode.success;
    }
  }

  /// Toggles the theme based on the currently resolved [visualBrightness].
  void toggleTheme(Brightness visualBrightness) {
    if (isClosed) return;
    final bool isCurrentlyDark = visualBrightness == Brightness.dark;
    emit(
      state.copyWith(
        themeMode: isCurrentlyDark ? ThemeMode.light : ThemeMode.dark,
      ),
    );
  }

  /// Changes the active tenant and reloads all data.
  /// Returns a Future that completes when reloads are finished.
  Future<void> changeTenant(String tenantId, String token) async {
    if (isClosed) return;

    // Tenant Isolation Guard: Clean out all previous details immediately
    emit(
      state.copyWith(
        tenantId: tenantId,
        token: token,
        messages: [],
        nextCursor: null,
        costBreakdown: null,
        sendStatus: SmsConsoleStatus.initial,
        historyStatus: HistoryStatus.initial,
        costStatus: CostStatus.initial,
      ),
    );

    // Refetch the data scopes immediately
    await Future.wait([loadCostBreakdown(), loadHistory(isRefresh: true)]);
  }

  /// Updates the fake server behavior mode.
  Future<void> changeServerMode(DevServerMode mode) async {
    if (isClosed) return;
    if (_repository is FakeSmsRepository) {
      _repository.mode = mode;
    }
    emit(
      state.copyWith(serverMode: mode, sendStatus: SmsConsoleStatus.initial),
    );
    await Future.wait([loadCostBreakdown(), loadHistory(isRefresh: true)]);
  }

  Future<void> loadCostBreakdown() async {
    if (isClosed) return;
    emit(state.copyWith(costStatus: CostStatus.loading));
    try {
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 30));

      final breakdown = await _repository.getCostBreakdown(
        tenantId: state.tenantId,
        token: state.token,
        from: fromDate,
        to: now,
      );

      if (isClosed) return;
      emit(
        state.copyWith(costStatus: CostStatus.loaded, costBreakdown: breakdown),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          costStatus: CostStatus.error,
          costErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadHistory({bool isRefresh = false}) async {
    if (isClosed) return;

    if (isRefresh) {
      emit(
        state.copyWith(
          historyStatus: HistoryStatus.loading,
          messages: const [],
          nextCursor: null,
        ),
      );
    } else {
      if (state.nextCursor == null) {
        return;
      }
      emit(state.copyWith(historyStatus: HistoryStatus.loadingMore));
    }

    try {
      final page = await _repository.getMessages(
        tenantId: state.tenantId,
        token: state.token,
        cursor: isRefresh ? null : state.nextCursor,
        limit: 10,
      );

      if (isClosed) return;

      final updatedMessages = isRefresh
          ? page.items
          : [...state.messages, ...page.items];

      emit(
        state.copyWith(
          historyStatus: HistoryStatus.loaded,
          messages: updatedMessages,
          nextCursor: page.nextCursor,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          historyStatus: HistoryStatus.error,
          historyErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> sendSms(String to, String body) async {
    if (isClosed) return;
    emit(
      state.copyWith(
        sendStatus: SmsConsoleStatus.loading,
        sendErrorMessage: null,
        lastSentMessageId: null,
      ),
    );

    try {
      final res = await _repository.sendSms(
        tenantId: state.tenantId,
        token: state.token,
        to: to,
        body: body,
      );

      if (isClosed) return;
      emit(
        state.copyWith(
          sendStatus: SmsConsoleStatus.success,
          lastSentMessageId: res.messageId,
        ),
      );

      // Auto-reload to immediately reflect updated billing/transaction items
      await Future.wait([loadCostBreakdown(), loadHistory(isRefresh: true)]);
    } catch (e) {
      if (isClosed) return;
      String errMsg = e.toString();
      if (e is SmsValidationException) {
        errMsg = '${e.message} (ErrorCode: ${e.errorCode})';
      }
      emit(
        state.copyWith(
          sendStatus: SmsConsoleStatus.failure,
          sendErrorMessage: errMsg,
        ),
      );
    }
  }
}
