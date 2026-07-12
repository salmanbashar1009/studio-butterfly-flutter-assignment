import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/sms_console_cubit.dart';
import '../state/sms_console_state.dart';
import 'cost_card.dart';

class CostCardConnector extends StatelessWidget {
  const CostCardConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
      buildWhen: (prev, curr) =>
          prev.costStatus != curr.costStatus ||
          prev.costBreakdown != curr.costBreakdown ||
          prev.costErrorMessage != curr.costErrorMessage,
      builder: (context, state) {
        return CostCard(
          breakdown: state.costBreakdown,
          isLoading: state.costStatus == CostStatus.loading,
          errorMessage: state.costErrorMessage,
          onRetry: () => context.read<SmsConsoleCubit>().loadCostBreakdown(),
        );
      },
    );
  }
}
