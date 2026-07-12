import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/sms_status.dart';

class SmsStatusChip extends StatelessWidget {
  final SmsStatus status;

  const SmsStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color textColor;
    switch (status) {
      case SmsStatus.accepted:
        color = Colors.yellow.shade100;
        textColor = Colors.yellow.shade900;
        break;
      case SmsStatus.sent:
        color = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      case SmsStatus.delivered:
        color = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case SmsStatus.failed:
        color = Colors.red.shade100;
        textColor = Colors.red.shade900;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
