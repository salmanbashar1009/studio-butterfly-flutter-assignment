import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_console/core/utils/dev_server_mode.dart';
import 'package:sms_console/data/repositories/fake_sms_repository.dart';
import 'package:sms_console/presentation/pages/sms_console_page.dart';
import 'package:sms_console/presentation/state/sms_console_cubit.dart';

void main() {
  late FakeSmsRepository fakeRepository;

  setUp(() {
    fakeRepository = FakeSmsRepository();
  });

  tearDown(() {
    fakeRepository.dispose();   // ← this line is the fix; add it right after setUp
  });
  Widget createTestWidget() {
    return MaterialApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<FakeSmsRepository>.value(value: fakeRepository),
        ],
        child: BlocProvider(
          create: (context) => SmsConsoleCubit(
            repository: fakeRepository,
            initialTenantId: '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
            initialToken: 'fw_live_8c21e0b47ad94f13ba77e0c9d51a3b62',
          ),
          child: const SmsConsolePage(),
        ),
      ),
    );
  }

  group('SMS Send Flow Widget Tests', () {
    testWidgets('Should show validation error when phone number format is invalid', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('phone_number_field')), '12345');
      await tester.enterText(find.byKey(const Key('message_body_field')), 'Hello World');
      await tester.pump();

      await tester.tap(find.byKey(const Key('send_sms_button')));
      await tester.pump();

      expect(find.text('Must be E.164 format (e.g. +4915112345678)'), findsOneWidget);
    });

    testWidgets('Should handle server validation / API failure path gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      fakeRepository.mode = DevServerMode.networkFailure;

      await tester.enterText(find.byKey(const Key('phone_number_field')), '+4915112345678');
      await tester.enterText(find.byKey(const Key('message_body_field')), 'Hello World');
      await tester.pump();

      await tester.tap(find.byKey(const Key('send_sms_button')));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump();

      expect(find.text('No internet connection. Please verify your connection.'), findsOneWidget);
    });



    testWidgets('Should successfully send SMS on correct inputs', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      fakeRepository.mode = DevServerMode.success;
      fakeRepository.latencyMs = 0;

      await tester.enterText(find.byKey(const Key('phone_number_field')), '+4915112345678');
      await tester.enterText(find.byKey(const Key('message_body_field')), 'Test success message');
      await tester.pump();

      await tester.tap(find.byKey(const Key('send_sms_button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsAtLeast(1));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.textContaining('SMS Accepted! ID:'), findsOneWidget);

      fakeRepository.dispose(); // ← cancel status-transition timers before the test body returns
    });
  });
}