import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../routes/app_routes.dart';

class CustomerBottomNav extends StatelessWidget {
  const CustomerBottomNav({
    super.key,
    required this.currentIndex,
  });

  final int currentIndex;

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    final route = switch (index) {
      0 => AppRoutes.customerHome,
      1 => AppRoutes.customerSearch,
      2 => AppRoutes.customerBookingHistory,
      3 => AppRoutes.customerProfile,
      _ => AppRoutes.customerHome,
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
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
