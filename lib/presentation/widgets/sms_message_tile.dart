import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/sms_message.dart';
import 'sms_status_chip.dart';

class SmsMessageTile extends StatelessWidget {
  final SmsMessage message;

  const SmsMessageTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.sms_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                message.recipient,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SmsStatusChip(status: message.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: ${message.messageId} • ${message.segmentCount} segment(s)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
              ),
              Text(
                message.cost.format(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
