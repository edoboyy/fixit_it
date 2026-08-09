import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../routes/app_routes.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    final route = switch (index) {
      0 => AppRoutes.adminDashboard,
      1 => AppRoutes.adminUsers,
      2 => AppRoutes.adminArtisans,
      3 => AppRoutes.adminBookings,
      4 => AppRoutes.adminPayments,
      _ => AppRoutes.adminDashboard,
    };

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onTap(context, index),
      indicatorColor: AppConstants.primaryGreen.withValues(alpha: 0.15),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Users',
        ),
        NavigationDestination(
          icon: Icon(Icons.handyman_outlined),
          selectedIcon: Icon(Icons.handyman),
          label: 'Artisans',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.payments_outlined),
          selectedIcon: Icon(Icons.payments),
          label: 'Payments',
        ),
      ],
    );
  }
}
