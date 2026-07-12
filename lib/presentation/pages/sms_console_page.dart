import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sms_console/presentation/state/sms_console_cubit.dart';
import 'package:sms_console/presentation/state/sms_console_state.dart';
import 'package:sms_console/presentation/widgets/sms_console_mobile_layout.dart';
import 'package:sms_console/presentation/widgets/sms_console_wide_layout.dart';

class SmsConsolePage extends StatefulWidget {
  const SmsConsolePage({super.key});

  @override
  State<SmsConsolePage> createState() => _SmsConsolePageState();
}

class _SmsConsolePageState extends State<SmsConsolePage> {
  // Use independent scroll controllers for the different layouts to avoid
  // "multiple clients" errors during responsive transitions.
  final ScrollController _mobileScrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();

  late SmsConsoleCubit _cubit;

  // GlobalKeys are critical here to preserve the State (and focus/input) of these
  // complex widgets when the LayoutBuilder swaps between Wide and Mobile layouts.
  // Without these, resizing the window would cause the Form to lose focus and text.
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _sendFormKey = GlobalKey();
  final GlobalKey _costCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cubit = context.read<SmsConsoleCubit>();

    // Initial data load
    _cubit.loadCostBreakdown();
    _cubit.loadHistory(isRefresh: true);
  }

  @override
  void dispose() {
    _mobileScrollController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  /// Handles "load more" pagination by listening to scroll notifications
  /// from any scrollable child (Mobile main view or Wide history view).
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent * 0.9) {
      _cubit.loadHistory();
    }
    return false;
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _cubit.loadCostBreakdown(),
      _cubit.loadHistory(isRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmsConsoleCubit, SmsConsoleState>(
      buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Formwork SMS Console',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                key: const Key('theme_toggle_button'),
                tooltip: 'Toggle Light/Dark Theme',
                icon: Icon(
                  state.themeMode == ThemeMode.dark
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                ),
                onPressed: () {
                  // Pass the current visual brightness so the Cubit knows
                  // which theme to switch to when themeMode is 'system'.
                  _cubit.toggleTheme(Theme.of(context).brightness);
                },
              ),
              IconButton(
                tooltip: 'Refresh all scopes',
                icon: const Icon(Icons.refresh),
                onPressed: _onRefresh,
              ),
            ],
          ),
          // Use BlocListener for side-effects like showing SnackBars.
          // This is safer than calling ScaffoldMessenger in build or didUpdateWidget.
          body: BlocListener<SmsConsoleCubit, SmsConsoleState>(
            listenWhen: (prev, curr) =>
            prev.lastSentMessageId != curr.lastSentMessageId ||
                prev.sendErrorMessage != curr.sendErrorMessage,
            listener: (context, state) {
              if (state.lastSentMessageId != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('SMS Accepted! ID: ${state.lastSentMessageId}'),
                    backgroundColor: Colors.green.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (state.sendErrorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.sendErrorMessage!),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Adaptive breakpoint: Desktop gets a dual-pane layout.
                      final isWide = constraints.maxWidth >= 900;
                      return SafeArea(
                        child: RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: isWide
                              ? SmsConsoleWideLayout(
                            historyScrollController: _historyScrollController,
                            settingsKey: _settingsKey,
                            sendFormKey: _sendFormKey,
                            costCardKey: _costCardKey,
                          )
                              : SmsConsoleMobileLayout(
                            mobileScrollController: _mobileScrollController,
                            settingsKey: _settingsKey,
                            sendFormKey: _sendFormKey,
                            costCardKey: _costCardKey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
