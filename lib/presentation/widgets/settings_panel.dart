import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/dev_server_mode.dart';
import '../state/sms_console_cubit.dart';
import '../state/sms_console_state.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SmsConsoleCubit>();

    return BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
      buildWhen: (prev, curr) =>
          prev.tenantId != curr.tenantId || prev.serverMode != curr.serverMode,
      builder: (context, state) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Environment Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: state.tenantId,
                  decoration: const InputDecoration(
                    labelText: 'Active Tenant Scope',
                    prefixIcon: Icon(Icons.domain_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '9f1c2d3e-4a5b-6c7d-8e9f-0a1b2c3d4e5f',
                      child: Text('Tenant A (EUR / Europe)'),
                    ),
                    DropdownMenuItem(
                      value: 'tenant-usd-uuid-12345',
                      child: Text('Tenant B (USD / Americas)'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      final token = val == 'tenant-usd-uuid-12345'
                          ? 'dummy_token_usd'
                          : 'dummy_token_eur';
                      cubit.changeTenant(val, token);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.s),
                DropdownButtonFormField<DevServerMode>(
                  isExpanded: true,
                  initialValue: state.serverMode,
                  decoration: const InputDecoration(
                    labelText: 'API Stub Mode',
                    prefixIcon: Icon(Icons.bug_report_outlined),
                  ),
                  items: DevServerMode.values.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(_getServerModeLabel(mode)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      cubit.changeServerMode(val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.s),
                const Text(
                  'Note: Stub mode is available only for testing and review. It is not included in the production app.',
                )
              ],
            ),
          ),
        );
      },
    );
  }

  String _getServerModeLabel(DevServerMode mode) {
    switch (mode) {
      case DevServerMode.success:
        return 'Success (API working)';
      case DevServerMode.empty:
        return 'Success (Empty dataset)';
      case DevServerMode.networkFailure:
        return 'Offline (Network Failure)';
      case DevServerMode.timeout:
        return 'Timeout (Latency failure)';
      case DevServerMode.serverError:
        return 'Server Error (HTTP 500)';
      case DevServerMode.rateLimit429:
        return 'Rate Limited (HTTP 429)';
    }
  }
}
