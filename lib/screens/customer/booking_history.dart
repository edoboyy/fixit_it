import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/booking_workflow.dart';
import '../../core/utils/helpers.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/customer_bottom_nav.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/payment_simulation_dialog.dart';
import '../../widgets/review_dialog.dart';
import '../../widgets/success_dialog.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context.read<BookingProvider>().watchBookingHistory(
            userId: userId,
            force: true,
          );
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

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
      if (error != null) {
        Helpers.showSnackBar(context, error, isError: true);
      }
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

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: bookingProvider.isLoading
          ? const LoadingWidget(message: 'Loading bookings...')
          : TabBarView(
              controller: _tabController,
              children: [
                _BookingList(
                  bookings: bookingProvider.pendingBookings,
                  emptyMessage: 'No active bookings',
                  onCancel: _cancelBooking,
                  onConfirm: _confirmBooking,
                  showTracker: true,
                ),
                _BookingList(
                  bookings: bookingProvider.completedBookings,
                  emptyMessage: 'No completed bookings',
                  showTracker: true,
                  onReview: _writeReview,
                ),
                _BookingList(
                  bookings: bookingProvider.cancelledBookings,
                  emptyMessage: 'No cancelled bookings',
                ),
              ],
            ),
      bottomNavigationBar: const CustomerBottomNav(currentIndex: 2),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
    this.onCancel,
    this.onConfirm,
    this.onReview,
    this.showTracker = false,
  });

  final List<BookingModel> bookings;
  final String emptyMessage;
  final void Function(String bookingId)? onCancel;
  final void Function(String bookingId)? onConfirm;
  final void Function(String bookingId)? onReview;
  final bool showTracker;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyStateWidget(
        message: emptyMessage,
        icon: Icons.event_busy_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthProvider>().currentUser?.id;
        if (userId != null) {
          await context.read<BookingProvider>().watchBookingHistory(
                userId: userId,
                force: true,
              );
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingCard(
            booking: booking,
            showTracker: showTracker,
            onCancel: onCancel != null
                ? () => onCancel!(booking.id)
                : null,
            onConfirm: onConfirm != null
                ? () => onConfirm!(booking.id)
                : null,
            onReview: onReview != null
                ? () => onReview!(booking.id)
                : null,
          );
        },
      ),
    );
  }
}
