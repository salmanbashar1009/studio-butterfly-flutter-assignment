import 'package:flutter/material.dart';
import 'package:sms_console/core/theme/app_theme.dart';

class SmsSendForm extends StatefulWidget {
  final bool isLoading;
  final String? lastSentMessageId;
  final String? sendErrorMessage;
  final Function(String to, String body) onSend;

  const SmsSendForm({
    super.key,
    required this.isLoading,
    this.lastSentMessageId,
    this.sendErrorMessage,
    required this.onSend,
  });

  @override
  State<SmsSendForm> createState() => _SmsSendFormState();
}

class _SmsSendFormState extends State<SmsSendForm> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final to = _phoneController.text.trim();
      final body = _bodyController.text.trim();

      _phoneController.clear();
      _bodyController.clear();
      _formKey.currentState?.reset();

      FocusScope.of(context).unfocus();

      widget.onSend(to, body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send Single SMS',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.m),

              // Phone field with stable Key
              Semantics(
                label: 'Phone number input field',
                child: TextFormField(
                  key: const Key('phone_number_field'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+4915112345678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    final phoneRegex = RegExp(r'^\+[1-9]\d{1,14}$');
                    if (!phoneRegex.hasMatch(value.trim())) {
                      return 'Must be E.164 format (e.g. +4915112345678)';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Message field with stable Key
              Semantics(
                label: 'Message body text field',
                child: TextFormField(
                  key: const Key('message_body_field'),
                  controller: _bodyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message Body',
                    hintText: 'Type your message...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 40.0),
                      child: Icon(Icons.message_outlined),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Message body is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.l),

              // Button with stable Key
              Semantics(
                label: widget.isLoading ? 'Sending SMS' : 'Send SMS button',
                child: ElevatedButton(
                  key: const Key('send_sms_button'),
                  onPressed: widget.isLoading ? null : _submitForm,
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send SMS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
