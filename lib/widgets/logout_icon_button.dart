import 'package:flutter/material.dart';

import '../core/utils/helpers.dart';

/// App-bar logout icon used by customer, artisan, and admin screens.
class LogoutIconButton extends StatelessWidget {
  const LogoutIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Logout',
      onPressed: () => Helpers.confirmAndLogout(context),
      icon: const Icon(Icons.logout),
    );
  }
}
