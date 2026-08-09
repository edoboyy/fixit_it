import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/fade_slide_in.dart';

/// Role picker shown after splash when the user is not signed in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _continueAs(BuildContext context, UserRole role) {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstants.primaryGreen.withValues(alpha: 0.12),
              theme.scaffoldBackgroundColor,
              AppConstants.accentGold.withValues(alpha: 0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                FadeSlideIn(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.primaryGreen.withValues(alpha: 0.12),
                        ),
                        child: const PulseIcon(
                          icon: Icons.handyman_rounded,
                          size: 52,
                          color: AppConstants.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.appName,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppConstants.appTagline,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Continue as',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: _RoleCard(
                          title: 'Customer',
                          subtitle:
                              'Find artisans, book jobs, track work, Confirm & Pay',
                          icon: Icons.person_rounded,
                          color: const Color(0xFF1B6CA8),
                          onTap: () =>
                              _continueAs(context, UserRole.customer),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: _RoleCard(
                          title: 'Artisan',
                          subtitle:
                              'Accept approved jobs, update status, earn payments',
                          icon: Icons.handyman_rounded,
                          color: AppConstants.primaryGreen,
                          onTap: () => _continueAs(context, UserRole.artisan),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 240),
                        child: _RoleCard(
                          title: 'Admin',
                          subtitle:
                              'Verify artisans, approve bookings, monitor the platform',
                          icon: Icons.admin_panel_settings_rounded,
                          color: AppConstants.accentRed,
                          onTap: () => _continueAs(context, UserRole.admin),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
