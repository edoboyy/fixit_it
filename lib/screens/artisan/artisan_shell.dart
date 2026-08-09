import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/artisan_bottom_nav.dart';
import 'artisan_home.dart';
import 'booking_requests.dart';
import 'earnings.dart';
import 'profile.dart';

/// Single artisan host so tabs share one booking load and tight layout bounds.
class ArtisanShell extends StatefulWidget {
  const ArtisanShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<ArtisanShell> createState() => _ArtisanShellState();
}

class _ArtisanShellState extends State<ArtisanShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSharedData());
  }

  Future<void> _loadSharedData() async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ?? auth.authUser?.id;
    if (userId == null) return;

    await context.read<BookingProvider>().loadBookingHistory(
          userId: userId,
          asArtisan: true,
        );
    if (!mounted) return;
    context.read<NotificationProvider>().watchNotifications(userId);
  }

  void _setIndex(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          ArtisanHomeScreen(
            embedded: true,
            onOpenRequests: () => _setIndex(1),
            onRefresh: _loadSharedData,
          ),
          BookingRequestsScreen(
            embedded: true,
            onRefresh: _loadSharedData,
          ),
          const ArtisanProfileScreen(embedded: true),
          const EarningsScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: ArtisanBottomNav(
        currentIndex: _index,
        onTap: _setIndex,
      ),
    );
  }
}
