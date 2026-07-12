import 'package:flutter_test/flutter_test.dart';
import 'package:sms_console/core/utils/dev_server_mode.dart';
import 'package:sms_console/core/utils/money.dart';
import 'package:sms_console/data/repositories/fake_sms_repository.dart';
import 'package:sms_console/presentation/state/sms_console_cubit.dart';
import 'package:sms_console/presentation/state/sms_console_state.dart';
import 'package:sms_console/domain/models/sms_message.dart';
import 'package:sms_console/domain/models/sms_status.dart';

void main() {
  late FakeSmsRepository repository;
  late SmsConsoleCubit cubit;

  const tenantA = '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f';
  const tokenA = 'dev_mock_token_12345';

  setUp(() {
    repository = FakeSmsRepository();
    repository.latencyMs = 0; // Speed up tests

    cubit = SmsConsoleCubit(
      repository: repository,
      initialTenantId: tenantA,
      initialToken: tokenA,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('SmsConsoleCubit Tests', () {
    test('Initial state should be correct', () {
      expect(cubit.state.tenantId, equals(tenantA));
      expect(cubit.state.token, equals(tokenA));
      expect(cubit.state.historyStatus, equals(HistoryStatus.initial));
    });

    test('changeTenant should reset state and trigger reloads', () async {
      const newTenant = 'tenant-usd-uuid-12345';
      const newToken = 'dummy_token_usd';

      // Await the full transition to prevent "emit after close" in teardown
      await cubit.changeTenant(newTenant, newToken);

      expect(cubit.state.tenantId, equals(newTenant));
      expect(cubit.state.token, equals(newToken));
      expect(cubit.state.historyStatus, equals(HistoryStatus.loaded));
    });

    test('sendSms failure should update state with error message', () async {
      await cubit.changeServerMode(DevServerMode.rateLimit429);

      await cubit.sendSms('+4915112345678', 'Hello');

      expect(cubit.state.sendStatus, equals(SmsConsoleStatus.failure));
      expect(cubit.state.sendErrorMessage, contains('Rate limit exceeded'));
    });

    test('loadHistory should handle pagination correctly', () async {
      repository.clearAllData();

      await cubit.loadHistory(isRefresh: true);
      expect(cubit.state.messages, isEmpty);

      // Seed data
      final messagesList = repository.getTenantMessagesForTest(tenantA);
      messagesList.clear();
      for (int i = 0; i < 15; i++) {
        messagesList.add(
          SmsMessage(
            messageId: 'SEED_${i.toString().padLeft(3, '0')}',
            recipient: '+491510000${i.toString().padLeft(2, '0')}',
            status: SmsStatus.delivered,
            segmentCount: 1,
            cost: Money.fromDecimalString('0.075', 'EUR'),
            sentAt: DateTime.now().subtract(Duration(minutes: 30 + i)),
            provider: 'TWILIO',
          ),
        );
      }
      messagesList.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      // First page
      await cubit.loadHistory(isRefresh: true);
      expect(cubit.state.messages.length, 10, reason: 'First page');

      // Load more - give time for state to update
      await cubit.loadHistory();
      await Future.delayed(
        const Duration(milliseconds: 50),
      ); // small delay for emit

      expect(
        cubit.state.messages.length,
        15,
        reason: 'After loading more, should have all 15 messages',
      );

      expect(cubit.state.nextCursor, isNull, reason: 'No more pages');
    });
  });
}
