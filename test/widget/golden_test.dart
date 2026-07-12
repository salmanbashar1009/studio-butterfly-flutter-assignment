import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_console/data/repositories/fake_sms_repository.dart';
import 'package:sms_console/presentation/pages/sms_console_page.dart';
import 'package:sms_console/presentation/state/sms_console_cubit.dart';

void main() {
  testWidgets('Main Console Screen - Golden Test', (WidgetTester tester) async {
    // Configure screen size to simulate desktop 1400px width
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;

    final fakeRepository = FakeSmsRepository();

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
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
      ),
    );

    // Complete local latency
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Assert that the UI matches the reference image
    await expectLater(
      find.byType(SmsConsolePage),
      matchesGoldenFile('goldens/main_console_desktop.png'),
    );
  });
}
