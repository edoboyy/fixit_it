import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/booking_workflow.dart';
import '../../core/utils/helpers.dart';
import '../../models/booking_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/artisan_bottom_nav.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/final_price_dialog.dart';
import '../../widgets/loading_widget.dart';

class BookingRequestsScreen extends StatefulWidget {
  const BookingRequestsScreen({
    super.key,
    this.embedded = false,
    this.onRefresh,
  });

  /// When true, hosted inside [ArtisanShell] — data is loaded by the shell.
  final bool embedded;
  final Future<void> Function()? onRefresh;

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  String? _loadError;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.embedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
    }
  }

  String? _resolveUserId(AuthProvider auth) {
    return auth.currentUser?.id ?? auth.authUser?.id;
  }

  Future<void> _loadRequests() async {
    if (_loading) return;

    if (widget.onRefresh != null) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
      await widget.onRefresh!();
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final auth = context.read<AuthProvider>();
    final userId = _resolveUserId(auth);
    if (userId == null) {
      setState(() => _loadError = 'Not signed in. Please log in again.');
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    final success = await context.read<BookingProvider>().loadBookingHistory(
          userId: userId,
          asArtisan: true,
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!success) {
        _loadError = context.read<BookingProvider>().errorMessage ??
            'Could not load bookings.';
      }
    });
  }

  Future<void> _accept(String bookingId) async {
    final success =
        await context.read<BookingProvider>().acceptBooking(bookingId);
    if (!mounted) return;
    if (success) {
      Helpers.showSnackBar(
        context,
        'Accepted. Next: On my way → Start work → Mark done',
        isSuccess: true,
      );
      await _loadRequests();
    } else {
      final error = context.read<BookingProvider>().errorMessage;
      if (error != null) {
        Helpers.showSnackBar(context, error, isError: true);
      }
    }
  }

  Future<void> _reject(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject booking?'),
        content: const Text('The customer will be notified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success =
        await context.read<BookingProvider>().rejectBooking(bookingId);
    if (!mounted) return;
    if (success) {
      Helpers.showSnackBar(context, 'Booking rejected');
      await _loadRequests();
    }
  }

  Future<void> _advance(BookingModel booking) async {
    double? finalPrice;
    if (BookingWorkflow.canSetFinalPrice(booking.status)) {
      finalPrice = await showFinalPriceDialog(context, booking);
      if (finalPrice == null || !mounted) return;
    }

    final previous = booking.status;
    final success = await context.read<BookingProvider>().advanceBooking(
          booking.id,
          finalPrice: finalPrice,
        );
    if (!mounted) return;

    if (success) {
      final message = switch (previous) {
        BookingStatus.accepted => 'On the way',
        BookingStatus.travelling => 'Work started',
        BookingStatus.working =>
          'Marked done — waiting for customer to Confirm & Pay',
        _ => 'Updated',
      };
      Helpers.showSnackBar(context, message, isSuccess: true);
      await _loadRequests();
    } else {
      final error = context.read<BookingProvider>().errorMessage;
      if (error != null) {
        Helpers.showSnackBar(context, error, isError: true);
      }
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _empty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final requests = bookingProvider.requestBookings;
    final activeJobs = bookingProvider.activeJobs;
    final awaitingConfirmation = bookingProvider.awaitingCustomerConfirmation;
    final showInitialLoader = (_loading || bookingProvider.isLoading) &&
        bookingProvider.bookings.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _loadRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: showInitialLoader
          ? const LoadingWidget(message: 'Loading requests...')
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_loading || bookingProvider.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    ),
                  Material(
                    color: AppConstants.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Flow: Accept → On my way → Start work → Mark done → '
                        'Customer Confirm & Pay',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Signed in as ${user.name} (${user.email})',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  if (_loadError != null) ...[
                    const SizedBox(height: 12),
                    Material(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _loadError!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Loaded ${bookingProvider.bookings.length} booking(s) total '
                    '(${requests.length} new request'
                    '${requests.length == 1 ? '' : 's'})',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  _sectionTitle(
                    '1. New Requests — Accept (${requests.length})',
                  ),
                  if (requests.isEmpty)
                    _empty('No new requests. Pull to refresh.')
                  else
                    ...requests.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BookingCard(
                          booking: booking,
                          onAccept: () => _accept(booking.id),
                          onReject: () => _reject(booking.id),
                        ),
                      ),
                    ),
                  _sectionTitle(
                    '2. Active Jobs — Work (${activeJobs.length})',
                  ),
                  if (activeJobs.isEmpty)
                    _empty('Accept a request to start working.')
                  else
                    ...activeJobs.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BookingCard(
                          booking: booking,
                          onAdvance: () => _advance(booking),
                        ),
                      ),
                    ),
                  _sectionTitle(
                    '3. Done — Waiting for payment (${awaitingConfirmation.length})',
                  ),
                  if (awaitingConfirmation.isEmpty)
                    _empty('Mark a job done to wait for customer payment.')
                  else
                    ...awaitingConfirmation.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BookingCard(
                          booking: booking,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: widget.embedded
          ? null
          : const ArtisanBottomNav(currentIndex: 1),
    );
  }
}
