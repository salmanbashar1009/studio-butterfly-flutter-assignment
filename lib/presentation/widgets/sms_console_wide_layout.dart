import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'settings_panel.dart';
import 'sms_send_form_connector.dart';
import 'cost_card_connector.dart';
import 'sms_history_list.dart';

class SmsConsoleWideLayout extends StatelessWidget {
  final ScrollController historyScrollController;
  final Key settingsKey;
  final Key sendFormKey;
  final Key costCardKey;

  const SmsConsoleWideLayout({
    super.key,
    required this.historyScrollController,
    required this.settingsKey,
    required this.sendFormKey,
    required this.costCardKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SettingsPanel(key: settingsKey),
                  const SizedBox(height: AppSpacing.m),
                  SmsSendFormConnector(key: sendFormKey),
                  const SizedBox(height: AppSpacing.m),
                  CostCardConnector(key: costCardKey),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            flex: 7,
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message Transaction Log',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Expanded(
                      child: SmsHistoryList(
                        controller: historyScrollController,
                        shrinkWrap: false,
                        physics: const AlwaysScrollableScrollPhysics(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
