import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/payment_model.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/logout_icon_button.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadPayments();
    });
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payments'),
        actions: const [LogoutIconButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadPayments(),
        child: admin.isLoading && admin.payments.isEmpty
            ? const LoadingWidget(message: 'Loading payments...')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet,
                            color: AppConstants.primaryGreen,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Revenue',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'GHS ${admin.totalRevenue.toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (admin.payments.isEmpty)
                    const EmptyStateWidget(
                      title: 'No payments found',
                      message: 'Released payments will appear in this list.',
                      icon: Icons.payments_outlined,
                    )
                  else
                    ...admin.payments.map(
                      (payment) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppConstants.primaryGreen
                                .withValues(alpha: 0.12),
                            child: const Icon(
                              Icons.payment,
                              color: AppConstants.primaryGreen,
                            ),
                          ),
                          title: Text(
                            'GHS ${payment.amount.toStringAsFixed(2)}',
                          ),
                          subtitle: Text(
                            '${_dateLabel(payment.createdAt)} · '
                            '${payment.method.name}\n'
                            'Ref: ${payment.reference ?? payment.id}',
                          ),
                          isThreeLine: true,
                          trailing: _StatusChip(status: payment.status),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 4),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PaymentStatus.pending => ('Pending', Colors.orange),
      PaymentStatus.completed => ('Paid', Colors.green),
      PaymentStatus.failed => ('Failed', Colors.red),
      PaymentStatus.refunded => ('Refunded', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
