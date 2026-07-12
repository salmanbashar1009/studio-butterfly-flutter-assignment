import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../state/sms_console_cubit.dart';
import '../state/sms_console_state.dart';
import 'sms_message_tile.dart';

class SmsHistoryList extends StatelessWidget {
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics physics;

  const SmsHistoryList({
    super.key,
    this.controller,
    required this.shrinkWrap,
    required this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
      buildWhen: (prev, curr) =>
          prev.historyStatus != curr.historyStatus ||
          prev.messages != curr.messages ||
          prev.historyErrorMessage != curr.historyErrorMessage,
      builder: (context, state) {
        if (state.historyStatus == HistoryStatus.loading && state.messages.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.l),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.historyStatus == HistoryStatus.error && state.messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Failed to load message log',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    state.historyErrorMessage ?? 'Connection error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  OutlinedButton.icon(
                    onPressed: () => context.read<SmsConsoleCubit>().loadHistory(isRefresh: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state.messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  const Text(
                    'No SMS Log Found',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'All outgoing text records will display here.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          key: const PageStorageKey('sms_history_list'),
          controller: controller,
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: state.messages.length + (state.nextCursor != null ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.messages.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.m),
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final msg = state.messages[index];
            return SmsMessageTile(message: msg);
          },
        );
      },
    );
  }
}
