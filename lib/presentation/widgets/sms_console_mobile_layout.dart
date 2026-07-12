import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'settings_panel.dart';
import 'sms_send_form_connector.dart';
import 'cost_card_connector.dart';
import 'sms_history_list.dart';

class SmsConsoleMobileLayout extends StatelessWidget {
  final ScrollController mobileScrollController;
  final Key settingsKey;
  final Key sendFormKey;
  final Key costCardKey;

  const SmsConsoleMobileLayout({
    super.key,
    required this.mobileScrollController,
    required this.settingsKey,
    required this.sendFormKey,
    required this.costCardKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: mobileScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsPanel(key: settingsKey),
            const SizedBox(height: AppSpacing.m),
            SmsSendFormConnector(key: sendFormKey),
            const SizedBox(height: AppSpacing.m),
            CostCardConnector(key: costCardKey),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Message Transaction Log',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.s),
            const SmsHistoryList(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
            ),
          ],
        ),
      ),
    );
  }
}
