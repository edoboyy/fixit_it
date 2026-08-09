import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../routes/app_routes.dart';

class ArtisanBottomNav extends StatelessWidget {
  const ArtisanBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (onTap != null) {
      onTap!(index);
      return;
    }

    final route = switch (index) {
      0 => AppRoutes.artisanHome,
      1 => AppRoutes.artisanBookingRequests,
      2 => AppRoutes.artisanProfile,
      3 => AppRoutes.artisanEarnings,
      _ => AppRoutes.artisanHome,
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
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: 'Requests',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        NavigationDestination(
          icon: Icon(Icons.payments_outlined),
          selectedIcon: Icon(Icons.payments),
          label: 'Earnings',
        ),
      ],
    );
  }
}
