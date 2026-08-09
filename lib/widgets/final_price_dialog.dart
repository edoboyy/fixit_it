import 'package:flutter/material.dart';

import '../models/booking_model.dart';

/// Prompts the artisan for the final job price before marking completed.
Future<double?> showFinalPriceDialog(
  BuildContext context,
  BookingModel booking,
) async {
  final controller = TextEditingController(
    text: (booking.finalPrice ?? booking.estimatedPrice).toStringAsFixed(0),
  );

  final result = await showDialog<double>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Set final price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated: GHS ${booking.estimatedPrice.toStringAsFixed(0)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Final price (GHS)',
                prefixText: 'GHS ',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(controller.text.trim());
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid price')),
                );
                return;
              }
              Navigator.pop(context, price);
            },
            child: const Text('Mark done'),
          ),
        ],
      );
    },
  );

  controller.dispose();
  return result;
}
