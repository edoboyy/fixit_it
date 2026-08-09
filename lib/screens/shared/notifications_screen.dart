import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) {
        context.read<NotificationProvider>().watchNotifications(userId);
      }
    });
  }

  Future<void> _markAllRead() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;
    await context.read<NotificationProvider>().markAllAsRead(userId);
  }

  IconData _iconFor(NotificationType type) {
    return switch (type) {
      NotificationType.bookingAccepted => Icons.check_circle_outline,
      NotificationType.bookingRejected => Icons.cancel_outlined,
      NotificationType.artisanTravelling => Icons.directions_car_outlined,
      NotificationType.workStarted => Icons.build_outlined,
      NotificationType.jobCompleted => Icons.task_alt_outlined,
      NotificationType.paymentReleased => Icons.payments_outlined,
      NotificationType.bookingCancelled => Icons.event_busy_outlined,
      NotificationType.newBooking => Icons.inbox_outlined,
      NotificationType.adminApprovedJob => Icons.verified_outlined,
      NotificationType.adminRejectedJob => Icons.block_outlined,
      NotificationType.artisanVerified => Icons.verified_user_outlined,
      NotificationType.awaitingAdminApproval => Icons.pending_actions_outlined,
    };
  }

  Color _colorFor(NotificationType type) {
    return switch (type) {
      NotificationType.bookingAccepted => Colors.green,
      NotificationType.bookingRejected => Colors.red,
      NotificationType.artisanTravelling => Colors.indigo,
      NotificationType.workStarted => Colors.blue,
      NotificationType.jobCompleted => Colors.teal,
      NotificationType.paymentReleased => AppConstants.primaryGreen,
      NotificationType.bookingCancelled => Colors.grey,
      NotificationType.newBooking => Colors.orange,
      NotificationType.adminApprovedJob => AppConstants.primaryGreen,
      NotificationType.adminRejectedJob => Colors.red,
      NotificationType.artisanVerified => Colors.green,
      NotificationType.awaitingAdminApproval => Colors.deepOrange,
    };
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: provider.isLoading && provider.notifications.isEmpty
          ? const LoadingWidget(message: 'Loading notifications...')
          : provider.notifications.isEmpty
              ? const EmptyStateWidget(
                  title: 'No notifications yet',
                  message: 'Updates about your bookings will appear here.',
                  icon: Icons.notifications_none,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = provider.notifications[index];
                    final color = _colorFor(item.type);

                    return Card(
                      color: item.isRead
                          ? null
                          : AppConstants.primaryGreen.withValues(alpha: 0.06),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Icon(_iconFor(item.type), color: color),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight:
                                item.isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(item.body),
                            if (item.createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _dateLabel(item.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        isThreeLine: true,
                        onTap: item.isRead
                            ? null
                            : () => context
                                .read<NotificationProvider>()
                                .markAsRead(item.id),
                      ),
                    );
                  },
                ),
    );
  }
}
