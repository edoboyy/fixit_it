import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/booking_workflow.dart';
import '../../core/utils/helpers.dart';
import '../../models/artisan_model.dart';
import '../../providers/artisan_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/artisan_card.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/how_to_use_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/logout_icon_button.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/payment_simulation_dialog.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/review_dialog.dart';
import '../../widgets/success_dialog.dart';
import '../../widgets/welcome_header.dart';
import '../../models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final artisanProvider = context.read<ArtisanProvider>();
    final bookingProvider = context.read<BookingProvider>();
    final authProvider = context.read<AuthProvider>();

    await artisanProvider.loadArtisans();

    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      await bookingProvider.watchBookingHistory(userId: userId, force: true);
      if (!mounted) return;
      context.read<NotificationProvider>().watchNotifications(userId);
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final success =
        await context.read<BookingProvider>().cancelBooking(bookingId);
    if (!mounted) return;
    if (success) {
      Helpers.showSnackBar(context, 'Booking cancelled');
    }
  }

  Future<void> _confirmBooking(String bookingId) async {
    final booking = context
        .read<BookingProvider>()
        .bookings
        .where((b) => b.id == bookingId)
        .firstOrNull;

    if (booking == null) {
      Helpers.showSnackBar(context, 'Booking not found.', isError: true);
      return;
    }

    if (!BookingWorkflow.canCustomerConfirm(booking.status)) {
      Helpers.showSnackBar(
        context,
        'This job is not ready for payment yet '
        '(${BookingWorkflow.label(booking.status)}).',
        isError: true,
      );
      return;
    }

    final method = await PaymentSimulationDialog.show(context, booking);
    if (method == null || !mounted) return;

    final success = await context.read<BookingProvider>().confirmCompletion(
          bookingId,
          method: method,
        );

    if (!mounted) return;

    if (success) {
      await SuccessDialog.show(
        context,
        title: 'Payment released',
        message:
            'Simulated ${method.value} payment succeeded. '
            'The artisan has been paid for this job.',
      );
      if (!mounted) return;
      await _promptReview(bookingId);
    } else {
      final error = context.read<BookingProvider>().errorMessage;
      Helpers.showSnackBar(
        context,
        error ?? 'Payment could not be completed.',
        isError: true,
      );
    }
  }

  Future<void> _promptReview(String bookingId) async {
    final booking = context
        .read<BookingProvider>()
        .bookings
        .where((b) => b.id == bookingId)
        .firstOrNull;

    if (booking == null || !BookingWorkflow.canCustomerReview(booking)) return;

    final reviewed = await ReviewDialog.show(context, booking);
    if (!mounted) return;

    if (reviewed) {
      Helpers.showSnackBar(context, 'Thank you for your review!');
    }
  }

  Future<void> _writeReview(String bookingId) async {
    final booking = context
        .read<BookingProvider>()
        .bookings
        .where((b) => b.id == bookingId)
        .firstOrNull;

    if (booking == null) return;

    final reviewed = await ReviewDialog.show(context, booking);
    if (!mounted) return;

    if (reviewed) {
      Helpers.showSnackBar(context, 'Thank you for your review!');
    }
  }

  void _openArtisanProfile(ArtisanModel artisan) {
    Navigator.pushNamed(
      context,
      AppRoutes.customerArtisanProfile,
      arguments: artisan,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final artisanProvider = context.watch<ArtisanProvider>();
    final bookingProvider = context.watch<BookingProvider>();
    final user = authProvider.currentUser;
    final userName = user?.name ?? 'Guest';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: artisanProvider.isLoading && artisanProvider.allArtisans.isEmpty
            ? const LoadingWidget(message: 'Loading...')
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    title: Text(userName),
                    actions: [
                      IconButton(
                        tooltip: 'How to use',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.howToUse,
                        ),
                        icon: const Icon(Icons.help_outline_rounded),
                      ),
                      const NotificationBell(),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ProfileAvatar(
                          name: userName,
                          photoUrl: user?.photoUrl,
                          radius: 16,
                          showRing: false,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.customerProfile,
                          ),
                        ),
                      ),
                      const LogoutIconButton(),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user != null)
                            WelcomeHeader(
                              user: user,
                              onProfileTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.customerProfile,
                              ),
                            ),
                          const SizedBox(height: 14),
                          const HowToUseCard(role: UserRole.customer),
                          const SizedBox(height: 18),
                          FadeSlideIn(
                            delay: const Duration(milliseconds: 80),
                            child: _SearchBar(
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.customerSearch,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Categories',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: AppConstants.serviceCategories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final category =
                                    AppConstants.serviceCategories[index];
                                return ActionChip(
                                  label: Text(category),
                                  onPressed: () {
                                    artisanProvider.filter(category: category);
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.customerSearch,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: 'Popular Artisans',
                            onSeeAll: () => Navigator.pushNamed(
                              context,
                              AppRoutes.customerSearch,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (artisanProvider.popularArtisans.isEmpty)
                            const EmptyStateWidget(
                              message: 'No popular artisans yet',
                              icon: Icons.star_outline,
                            )
                          else
                            ...artisanProvider.popularArtisans.map(
                              (artisan) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ArtisanCard(
                                  artisan: artisan,
                                  onTap: () => _openArtisanProfile(artisan),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: 'Nearby Artisans',
                            onSeeAll: () => Navigator.pushNamed(
                              context,
                              AppRoutes.customerSearch,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (artisanProvider.nearbyArtisans.isEmpty)
                            const EmptyStateWidget(
                              message: 'No nearby artisans found',
                              icon: Icons.location_off_outlined,
                            )
                          else
                            ...artisanProvider.nearbyArtisans.map(
                              (artisan) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ArtisanCard(
                                  artisan: artisan,
                                  onTap: () => _openArtisanProfile(artisan),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          _SectionHeader(
                            title: 'Recent Bookings',
                            onSeeAll: () => Navigator.pushNamed(
                              context,
                              AppRoutes.customerBookingHistory,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (bookingProvider.recentBookings.isEmpty)
                            const EmptyStateWidget(
                              message: 'No recent bookings',
                              icon: Icons.calendar_today_outlined,
                            )
                          else
                            ...bookingProvider.recentBookings.map(
                              (booking) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: BookingCard(
                                  booking: booking,
                                  showTracker: true,
                                  onCancel: () => _cancelBooking(booking.id),
                                  onConfirm: () => _confirmBooking(booking.id),
                                  onReview: () => _writeReview(booking.id),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 0),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Text(
              'Search for artisans or services...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
      ],
    );
  }
}
