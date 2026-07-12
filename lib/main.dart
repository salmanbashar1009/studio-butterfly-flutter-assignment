import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_console/data/repositories/fake_sms_repository.dart';
import 'package:sms_console/data/repositories/http_sms_repository.dart';
import 'package:sms_console/domain/repositories/sms_repository.dart';
import 'package:sms_console/presentation/pages/sms_console_page.dart';
import 'package:sms_console/presentation/state/sms_console_cubit.dart';
import 'package:sms_console/presentation/state/sms_console_state.dart';
import 'package:sms_console/core/theme/app_theme.dart';

void main() {
  // Use environment variables for configuration. In a real production setup,
  // these would be injected at build time via --dart-define or --dart-define-from-file.
  const apiBaseUrl = String.fromEnvironment('SMS_API_BASE_URL');
  const tenantId = String.fromEnvironment(
    'SMS_TENANT_ID',
    defaultValue: '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
  );
  const apiToken = String.fromEnvironment(
    'SMS_API_TOKEN',
    defaultValue: 'fw_live_8c21e0b47ad94f13ba77e0c9d51a3b62',
  );

  // Choose repository based on environment configuration.
  // Defaults to FakeSmsRepository for local development and reviewer ease.
  final SmsRepository repository = apiBaseUrl.isNotEmpty
      ? HttpSmsRepository(baseUrl: apiBaseUrl)
      : FakeSmsRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [RepositoryProvider<SmsRepository>.value(value: repository)],
      child: BlocProvider(
        create: (context) => SmsConsoleCubit(
          repository: repository,
          initialTenantId: tenantId,
          initialToken: apiToken,
        ),
        child: const SmsConsoleApp(),
      ),
    ),
  );
}

class SmsConsoleApp extends StatelessWidget {
  const SmsConsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap MaterialApp with BlocBuilder to react to theme changes in the Cubit
    return BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
      buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
      builder: (context, state) {
        return MaterialApp(
          title: 'Formwork SMS Console',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.themeMode,
          home: const SmsConsolePage(),
        );
      },
    );
  }
}
