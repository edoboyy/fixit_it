import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/responsive.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../models/user_model.dart';
import '../../widgets/admin_bottom_nav.dart';
import '../../widgets/error_state_widget.dart';
import '../../widgets/fade_slide_in.dart';
import '../../widgets/how_to_use_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/logout_icon_button.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/welcome_header.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<AdminProvider>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final user = context.watch<AuthProvider>().currentUser;
    final name = user?.name ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          IconButton(
            tooltip: 'How to use',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.howToUse),
            icon: const Icon(Icons.help_outline_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ProfileAvatar(
              name: name,
              photoUrl: user?.photoUrl,
              radius: 16,
              showRing: false,
            ),
          ),
          const LogoutIconButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: admin.isLoading && admin.users.isEmpty
            ? const LoadingWidget(message: 'Loading dashboard...')
            : admin.errorMessage != null && admin.users.isEmpty
                ? ErrorStateWidget(
                    message: admin.errorMessage!,
                    onRetry: _load,
                  )
            : ListView(
                padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
                children: [
                  if (user != null) WelcomeHeader(user: user),
                  const SizedBox(height: 14),
                  const HowToUseCard(role: UserRole.admin),
                  const SizedBox(height: 18),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: GridView.count(
                    crossAxisCount: Responsive.gridColumns(context),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _StatTile(
                        label: 'Users',
                        value: '${admin.totalUsers}',
                        icon: Icons.people,
                        color: Colors.blue,
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.adminUsers,
                        ),
                      ),
                      _StatTile(
                        label: 'Artisans',
                        value: '${admin.totalArtisans}',
                        icon: Icons.handyman,
                        color: AppConstants.primaryGreen,
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.adminArtisans,
                        ),
                      ),
                      _StatTile(
                        label: 'Pending Verify',
                        value: '${admin.pendingVerifications}',
                        icon: Icons.verified_user_outlined,
                        color: Colors.orange,
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.adminArtisans,
                        ),
                      ),
                      _StatTile(
                        label: 'Bookings',
                        value: '${admin.totalBookings}',
                        icon: Icons.calendar_month,
                        color: Colors.purple,
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.adminBookings,
                        ),
                      ),
                      _StatTile(
                        label: 'Payments',
                        value: '${admin.totalPayments}',
                        icon: Icons.payments,
                        color: AppConstants.accentGold,
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.adminPayments,
                        ),
                      ),
                      _StatTile(
                        label: 'Revenue',
                        value: 'GHS ${admin.totalRevenue.toStringAsFixed(0)}',
                        icon: Icons.attach_money,
                        color: Colors.teal,
                        onTap: () => Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.adminPayments,
                        ),
                      ),
                    ],
                  ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Platform overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${admin.totalCustomers} customers · '
                    '${admin.totalArtisans} artisans · '
                    '${admin.activeBookings} active jobs',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _QuickAction(
                    title: 'Verify artisans',
                    subtitle: '${admin.pendingVerifications} awaiting review',
                    icon: Icons.verified,
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.adminArtisans,
                    ),
                  ),
                  _QuickAction(
                    title: 'Manage customers & artisans',
                    subtitle: '${admin.suspendedUsers} currently suspended',
                    icon: Icons.people_outline,
                    onTap: () {
                      Helpers.showSnackBar(
                        context,
                        'Open Users to view accounts and suspend/restore',
                      );
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.adminUsers,
                      );
                    },
                  ),
                  _QuickAction(
                    title: 'Approve jobs for artisans',
                    subtitle:
                        '${admin.awaitingApprovalBookings.length} waiting · '
                        '${admin.totalBookings} total bookings',
                    icon: Icons.assignment_turned_in_outlined,
                    onTap: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.adminBookings,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recent activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (admin.recentActivities.isEmpty)
                    Text(
                      'No recent activity yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    )
                  else
                    ...admin.recentActivities.map(
                      (activity) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                AppConstants.primaryGreen.withValues(alpha: 0.12),
                            child: Icon(
                              activity.icon,
                              color: AppConstants.primaryGreen,
                              size: 20,
                            ),
                          ),
                          title: Text(activity.title),
                          subtitle: Text(activity.subtitle),
                          trailing: Text(
                            _shortDate(activity.timestamp),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }

  String _shortDate(DateTime date) {
    return '${date.day}/${date.month} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppConstants.primaryGreen.withValues(alpha: 0.12),
          child: Icon(icon, color: AppConstants.primaryGreen),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
