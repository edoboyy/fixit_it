import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/booking_workflow.dart';
import '../models/booking_model.dart';
import 'booking_status_tracker.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
    this.onCancel,
    this.onAccept,
    this.onReject,
    this.onAdvance,
    this.onConfirm,
    this.onReview,
    this.showTracker = false,
  });

  final BookingModel booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onAdvance;
  final VoidCallback? onConfirm;
  final VoidCallback? onReview;
  final bool showTracker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final advanceLabel = BookingWorkflow.artisanActionLabel(booking.status);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.serviceCategory,
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                  ),
                  _StatusChip(status: booking.status),
                ],
              ),
              if (showTracker) ...[
                const SizedBox(height: 12),
                BookingStatusTracker(status: booking.status, compact: true),
              ],
              const SizedBox(height: 8),
              Text(
                booking.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(booking.scheduledDate),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      booking.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              if (onCancel != null &&
                  BookingWorkflow.canCustomerCancel(booking.status)) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onCancel,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppConstants.accentRed),
                    ),
                  ),
                ),
              ],
              if (onAccept != null &&
                  onReject != null &&
                  BookingWorkflow.canArtisanAccept(booking.status)) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: onReject,
                      child: const Text(
                        'Reject',
                        style: TextStyle(color: AppConstants.accentRed),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(88, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              ],
              if (onAdvance != null && advanceLabel != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onAdvance,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(advanceLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(88, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
              if (onConfirm != null &&
                  BookingWorkflow.canCustomerConfirm(booking.status)) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    icon: const Icon(Icons.verified, size: 18),
                    label: const Text('Confirm & Pay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentGold,
                      foregroundColor: AppConstants.darkText,
                      minimumSize: const Size(88, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
              if (onReview != null &&
                  BookingWorkflow.canCustomerReview(booking)) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onReview,
                    icon: const Icon(Icons.star, size: 18),
                    label: const Text('Write Review'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(88, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
              if (booking.hasReviewed &&
                  booking.status == BookingStatus.paid) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Review submitted',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final label = BookingWorkflow.label(status);
    final color = switch (status) {
      BookingStatus.awaitingApproval => Colors.deepOrange,
      BookingStatus.pending => Colors.orange,
      BookingStatus.accepted => Colors.blue,
      BookingStatus.travelling => Colors.teal,
      BookingStatus.working => Colors.purple,
      BookingStatus.completed => Colors.amber.shade800,
      BookingStatus.confirmed => Colors.green,
      BookingStatus.paid => AppConstants.primaryGreen,
      BookingStatus.cancelled => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
