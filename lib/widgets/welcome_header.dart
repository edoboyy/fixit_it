import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/constants/guide_content.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import 'fade_slide_in.dart';
import 'profile_avatar.dart';

/// Username welcome + profile avatar used on all role dashboards.
class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({
    super.key,
    required this.user,
    this.subtitle,
    this.onProfileTap,
    this.showHowTo = true,
  });

  final UserModel user;
  final String? subtitle;
  final VoidCallback? onProfileTap;
  final bool showHowTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedSubtitle = subtitle ?? GuideContent.roleSummary(user.role);

    return FadeSlideIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstants.primaryGreen,
              AppConstants.primaryGreen.withValues(alpha: 0.82),
              const Color(0xFF0A4D32),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryGreen.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  name: user.name,
                  photoUrl: user.photoUrl,
                  radius: 28,
                  onTap: onProfileTap,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _roleLabel(user.role),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppConstants.accentGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showHowTo)
                  IconButton(
                    tooltip: 'How to use Fixit GH',
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.howToUse,
                    ),
                    icon: const Icon(
                      Icons.help_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              resolvedSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _roleLabel(UserRole role) {
    return switch (role) {
      UserRole.customer => 'Customer account',
      UserRole.artisan => 'Artisan account',
      UserRole.admin => 'Admin account',
    };
  }
}
