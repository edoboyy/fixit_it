import 'package:flutter/material.dart';

import '../core/utils/booking_workflow.dart';
import '../models/booking_model.dart';
import '../widgets/booking_status_tracker.dart';

void showBookingDetailsSheet(BuildContext context, BookingModel booking) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              BookingStatusTracker(status: booking.status, compact: true),
              const SizedBox(height: 16),
              _DetailRow(
                label: 'Status',
                value: BookingWorkflow.label(booking.status),
              ),
              _DetailRow(label: 'Service', value: booking.serviceCategory),
              _DetailRow(
                label: 'Date',
                value: _formatDate(booking.scheduledDate),
              ),
              _DetailRow(label: 'Location', value: booking.location),
              _DetailRow(label: 'Description', value: booking.description),
              _DetailRow(
                label: 'Price',
                value: 'GHS ${booking.paymentAmount.toStringAsFixed(0)}',
              ),
              if (booking.customerConfirmedAt != null)
                _DetailRow(
                  label: 'Confirmed',
                  value: _formatDate(booking.customerConfirmedAt!),
                ),
              if (booking.paymentReleasedAt != null)
                _DetailRow(
                  label: 'Payment Released',
                  value: _formatDate(booking.paymentReleasedAt!),
                ),
              if (booking.notes != null)
                _DetailRow(label: 'Notes', value: booking.notes!),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
