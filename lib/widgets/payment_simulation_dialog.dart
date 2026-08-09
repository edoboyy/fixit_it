import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/validators.dart';
import '../models/booking_model.dart';
import '../models/payment_model.dart';
import 'custom_text_field.dart';

/// Simulates a Mobile Money checkout before releasing payment.
class PaymentSimulationDialog extends StatefulWidget {
  const PaymentSimulationDialog({super.key, required this.booking});

  final BookingModel booking;

  static Future<PaymentMethod?> show(
    BuildContext context,
    BookingModel booking,
  ) {
    return showDialog<PaymentMethod>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentSimulationDialog(booking: booking),
    );
  }

  @override
  State<PaymentSimulationDialog> createState() =>
      _PaymentSimulationDialogState();
}

class _PaymentSimulationDialogState extends State<PaymentSimulationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  PaymentMethod _method = PaymentMethod.mobileMoney;
  bool _processing = false;
  String? _statusText;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _processing = true;
      _statusText = _method == PaymentMethod.mobileMoney
          ? 'Sending MoMo prompt...'
          : _method == PaymentMethod.card
              ? 'Processing card payment...'
              : 'Recording cash payment...';
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _statusText = 'Authorizing payment...');
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    setState(() => _statusText = 'Payment successful');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    Navigator.pop(context, _method);
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.booking.paymentAmount;

    return AlertDialog(
      title: const Text('Simulate Payment'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pay GHS ${amount.toStringAsFixed(2)} for '
                '${widget.booking.serviceCategory}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                // ignore: deprecated_member_use
                value: _method,
                decoration: const InputDecoration(
                  labelText: 'Payment method',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: PaymentMethod.mobileMoney,
                    child: Text('Mobile Money'),
                  ),
                  DropdownMenuItem(
                    value: PaymentMethod.card,
                    child: Text('Card (simulated)'),
                  ),
                  DropdownMenuItem(
                    value: PaymentMethod.cash,
                    child: Text('Cash on completion'),
                  ),
                ],
                onChanged: _processing
                    ? null
                    : (value) {
                        if (value != null) setState(() => _method = value);
                      },
              ),
              if (_method != PaymentMethod.cash) ...[
                const SizedBox(height: 12),
                CustomTextField(
                  label: _method == PaymentMethod.mobileMoney
                      ? 'MoMo number'
                      : 'Phone for receipt',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_android,
                  autofillHints: const [],
                  enableSuggestions: false,
                  autocorrect: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: Validators.phone,
                ),
              ],
              if (_processing) ...[
                const SizedBox(height: 20),
                const LinearProgressIndicator(
                  color: AppConstants.primaryGreen,
                ),
                const SizedBox(height: 8),
                Text(
                  _statusText ?? 'Processing...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _processing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _processing ? null : _pay,
          child: Text(_processing ? 'Paying...' : 'Pay now'),
        ),
      ],
    );
  }
}