import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/booking_workflow.dart';
import '../../core/utils/helpers.dart';
import '../../models/booking_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/logout_icon_button.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  bool _needsApprovalOnly = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadBookings();
    });
  }

  String _dateLabel(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  Future<void> _approve(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve job?'),
        content: Text(
          'Send this ${booking.serviceCategory} job to the artisan.\n\n'
          'After this, the status becomes “Pending Artisan” and the artisan '
          'can Accept → work → Mark done.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve & Send'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final success =
        await context.read<AdminProvider>().approveBooking(booking.id);
    if (!mounted) return;

    Helpers.showSnackBar(
      context,
      success
          ? 'Approved — removed from this queue. Artisan can accept it now.'
          : (context.read<AdminProvider>().errorMessage ?? 'Approval failed'),
      isError: !success,
      isSuccess: success,
    );

    if (success && mounted) {
      setState(() {});
    }
  }

  Future<void> _reject(BookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject job?'),
        content: const Text(
          'The customer will be notified and the artisan will not see this job.',
        ),
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
        await context.read<AdminProvider>().rejectBooking(booking.id);
    if (!mounted) return;

    Helpers.showSnackBar(
      context,
      success
          ? 'Job rejected'
          : (context.read<AdminProvider>().errorMessage ?? 'Reject failed'),
      isError: !success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final awaitingCount = admin.awaitingApprovalBookings.length;
    final bookings = _needsApprovalOnly
        ? admin.awaitingApprovalBookings
        : admin.bookings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          awaitingCount > 0
              ? 'Manage Bookings ($awaitingCount to approve)'
              : 'Manage Bookings',
        ),
        actions: const [LogoutIconButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadBookings(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  FilterChip(
                    label: Text('Needs approval ($awaitingCount)'),
                    selected: _needsApprovalOnly,
                    selectedColor: Colors.orange.withValues(alpha: 0.35),
                    onSelected: (_) =>
                        setState(() => _needsApprovalOnly = true),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('All bookings'),
                    selected: !_needsApprovalOnly,
                    onSelected: (_) =>
                        setState(() => _needsApprovalOnly = false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: admin.isLoading && admin.bookings.isEmpty
                  ? const LoadingWidget(message: 'Loading bookings...')
                  : bookings.isEmpty
                      ? ListView(
                          children: [
                            EmptyStateWidget(
                              title: _needsApprovalOnly
                                  ? 'No jobs waiting for approval'
                                  : 'No bookings found',
                              message: _needsApprovalOnly
                                  ? 'When a customer books, it appears here. '
                                      'After you approve, it leaves this list '
                                      'and shows under the artisan’s Booking Requests.'
                                  : 'Bookings across the platform will show here.',
                              icon: Icons.calendar_month_outlined,
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookings.length,
                          itemBuilder: (context, index) {
                            final booking = bookings[index];
                            final canApprove =
                                BookingWorkflow.canAdminApprove(booking.status);
                            final canReject =
                                BookingWorkflow.canAdminReject(booking.status);
                            final withArtisan =
                                booking.status == BookingStatus.pending ||
                                    BookingWorkflow.isActive(booking.status) ||
                                    booking.status == BookingStatus.completed ||
                                    BookingWorkflow.isFinished(booking.status);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            booking.serviceCategory,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: canApprove
                                                ? Colors.orange
                                                    .withValues(alpha: 0.15)
                                                : AppConstants.primaryGreen
                                                    .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            BookingWorkflow.label(
                                              booking.status,
                                            ),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: canApprove
                                                  ? Colors.orange.shade800
                                                  : AppConstants.primaryGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(booking.description),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${booking.location}\n'
                                      '${_dateLabel(booking.scheduledDate)} · '
                                      'GHS ${booking.paymentAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (withArtisan && !canApprove) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Sent to artisan — they can accept and work on it.',
                                        style: TextStyle(
                                          color: AppConstants.primaryGreen,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (canApprove || canReject) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (canReject)
                                            TextButton(
                                              onPressed: admin.isLoading
                                                  ? null
                                                  : () => _reject(booking),
                                              child: const Text(
                                                'Reject',
                                                style: TextStyle(
                                                  color: AppConstants.accentRed,
                                                ),
                                              ),
                                            ),
                                          if (canApprove) ...[
                                            const SizedBox(width: 8),
                                            FilledButton.icon(
                                              onPressed: admin.isLoading
                                                  ? null
                                                  : () => _approve(booking),
                                              icon: const Icon(
                                                Icons.verified,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'Approve for artisan',
                                              ),
                                              style: FilledButton.styleFrom(
                                                backgroundColor:
                                                    AppConstants.primaryGreen,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
    );
  }
}
