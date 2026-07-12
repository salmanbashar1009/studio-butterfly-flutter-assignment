import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/sms_console_cubit.dart';
import '../state/sms_console_state.dart';
import 'sms_send_form.dart';

class SmsSendFormConnector extends StatelessWidget {
  const SmsSendFormConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
      buildWhen: (prev, curr) =>
          prev.sendStatus != curr.sendStatus ||
          prev.lastSentMessageId != curr.lastSentMessageId,
      builder: (context, state) {
        return SmsSendForm(
          isLoading: state.sendStatus == SmsConsoleStatus.loading,
          lastSentMessageId: state.lastSentMessageId,
          sendErrorMessage: state.sendErrorMessage,
          onSend: (to, body) =>
              context.read<SmsConsoleCubit>().sendSms(to, body),
        );
      },
    );
  }
}
