import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/onboarding_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/notification_provider.dart';
import '../../routes/app_routes.dart';

/// Shared login/register navigation: reset session data, then onboarding or home.
Future<void> navigateAfterAuth(BuildContext context) async {
  final auth = context.read<AuthProvider>();
  context.read<BookingProvider>().reset();
  context.read<NotificationProvider>().reset();

  final user = auth.currentUser;
  final showOnboarding = await OnboardingService.shouldShowFor(user);
  if (!context.mounted) return;

  final route = showOnboarding ? AppRoutes.onboarding : auth.destinationRoute;
  Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
}
