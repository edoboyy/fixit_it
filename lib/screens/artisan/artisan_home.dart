import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_routes.dart';
import '../../models/user_model.dart';
import '../../widgets/artisan_bottom_nav.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/final_price_dialog.dart';
import '../../widgets/how_to_use_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/logout_icon_button.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/welcome_header.dart';

class ArtisanHomeScreen extends StatefulWidget {
  const ArtisanHomeScreen({
    super.key,
    this.embedded = false,
    this.onOpenRequests,
    this.onRefresh,
  });

  /// When true, hosted inside [ArtisanShell] (no own bottom nav / initial load).
  final bool embedded;
  final VoidCallback? onOpenRequests;
  final Future<void> Function()? onRefresh;

  @override
  State<ArtisanHomeScreen> createState() => _ArtisanHomeScreenState();
}

class _ArtisanHomeScreenState extends State<ArtisanHomeScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
  }

  Future<void> _loadData() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
      return;
    }

    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ?? auth.authUser?.id;
    if (userId != null) {
      await context.read<BookingProvider>().loadBookingHistory(
            userId: userId,
            asArtisan: true,
          );
      if (!mounted) return;
      context.read<NotificationProvider>().watchNotifications(userId);
    }
  }

  void _openRequests() {
    if (widget.onOpenRequests != null) {
      widget.onOpenRequests!();
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.artisanBookingRequests,
    );
  }

  Future<void> _advanceJob(BookingModel booking) async {
    double? finalPrice;
    if (booking.status == BookingStatus.working) {
      finalPrice = await showFinalPriceDialog(context, booking);
      if (finalPrice == null || !mounted) return;
    }

    final success = await context.read<BookingProvider>().advanceBooking(
          booking.id,
          finalPrice: finalPrice,
        );
    if (!mounted) return;
    if (success) {
      Helpers.showSnackBar(context, 'Status updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final user = authProvider.currentUser;
    final name = user?.name ?? 'Artisan';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'How to use',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.howToUse),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          const NotificationBell(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ProfileAvatar(
              name: name,
              photoUrl: user?.photoUrl,
              radius: 16,
              showRing: false,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.artisanProfile,
              ),
            ),
          ),
          const LogoutIconButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: bookingProvider.isLoading && bookingProvider.bookings.isEmpty
            ? const LoadingWidget(message: 'Loading dashboard...')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (user != null)
                    WelcomeHeader(
                      user: user,
                      onProfileTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.artisanProfile,
                      ),
                    ),
                  const SizedBox(height: 14),
                  const HowToUseCard(role: UserRole.artisan),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Pending',
                            count: bookingProvider.artisanPendingJobs.length,
                            color: Colors.orange,
                            icon: Icons.pending_actions,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: "Today's Jobs",
                            count: bookingProvider.todaysJobs.length,
                            color: AppConstants.primaryGreen,
                            icon: Icons.today,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Completed',
                            count:
                                bookingProvider.artisanCompletedJobs.length,
                            color: Colors.green,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Requests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: _openRequests,
                        child: const Text('Open'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (bookingProvider.artisanPendingJobs.isEmpty)
                    const EmptyStateWidget(
                      compact: true,
                      message:
                          'No pending requests. After admin approves a booking, it shows here.',
                      icon: Icons.inbox_outlined,
                    )
                  else
                    ...bookingProvider.artisanPendingJobs.take(5).map(
                          (booking) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: BookingCard(
                              booking: booking,
                              onTap: _openRequests,
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.notifications,
                        ),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (notificationProvider.notifications.isEmpty)
                    const EmptyStateWidget(
                      message: 'No new notifications',
                      icon: Icons.notifications_none,
                      compact: true,
                    )
                  else
                    ...notificationProvider.notifications.take(3).map(
                          (item) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppConstants.primaryGreen
                                    .withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.notifications,
                                  color: item.isRead
                                      ? Colors.grey
                                      : AppConstants.primaryGreen,
                                ),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: item.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(item.body),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.notifications,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  Text(
                    "Today's Jobs",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  if (bookingProvider.todaysJobs.isEmpty)
                    const EmptyStateWidget(
                      compact: true,
                      message: 'No jobs scheduled for today',
                      icon: Icons.event_available_outlined,
                    )
                  else
                    ...bookingProvider.todaysJobs.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BookingCard(
                          booking: booking,
                          onAdvance: bookingProvider.activeJobs
                                  .any((b) => b.id == booking.id)
                              ? () => _advanceJob(booking)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : const ArtisanBottomNav(currentIndex: 0),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
