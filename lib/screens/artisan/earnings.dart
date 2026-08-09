import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/payment_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/earnings_provider.dart';
import '../../widgets/artisan_bottom_nav.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/loading_widget.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEarnings());
  }

  Future<void> _loadEarnings() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await context.read<EarningsProvider>().loadPayments(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final earningsProvider = context.watch<EarningsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEarnings,
        child: earningsProvider.isLoading
            ? const LoadingWidget(message: 'Loading earnings...')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _EarningsCard(
                          label: "Today's Earnings",
                          amount: earningsProvider.todayEarnings,
                          icon: Icons.today,
                          color: AppConstants.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _EarningsCard(
                          label: 'Monthly Earnings',
                          amount: earningsProvider.monthlyEarnings,
                          icon: Icons.calendar_month,
                          color: AppConstants.accentGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (earningsProvider.paymentHistory.isEmpty)
                    const EmptyStateWidget(
                      title: 'No payments yet',
                      message: 'Completed job payments will appear here.',
                      icon: Icons.account_balance_wallet_outlined,
                    )
                  else
                    ...earningsProvider.paymentHistory.map(
                      (payment) => _PaymentTile(payment: payment),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: widget.embedded
          ? null
          : const ArtisanBottomNav(currentIndex: 3),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              'GHS ${amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment});

  final PaymentModel payment;

  @override
  Widget build(BuildContext context) {
    final date = payment.createdAt;
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.primaryGreen.withValues(alpha: 0.1),
          child: const Icon(Icons.payment, color: AppConstants.primaryGreen),
        ),
        title: Text('GHS ${payment.amount.toStringAsFixed(2)}'),
        subtitle: Text('$dateStr · ${payment.method.name}'),
        trailing: _PaymentStatusChip(status: payment.status),
      ),
    );
  }
}

class _PaymentStatusChip extends StatelessWidget {
  const _PaymentStatusChip({required this.status});

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
