import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/guide_content.dart';
import '../../core/services/onboarding_service.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/fade_slide_in.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final role = user?.role ?? UserRole.customer;
    final steps = GuideContent.howToSteps(role);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('How to use Fixit GH')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FadeSlideIn(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppConstants.primaryGreen.withValues(alpha: 0.12),
                    AppConstants.accentGold.withValues(alpha: 0.14),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    GuideContent.roleHeadline(role),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    GuideContent.roleSummary(role),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Step by step',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            return FadeSlideIn(
              delay: Duration(milliseconds: 80 * i),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        AppConstants.primaryGreen.withValues(alpha: 0.12),
                    child: Icon(step.icon, color: AppConstants.primaryGreen),
                  ),
                  title: Text(
                    '${i + 1}. ${step.title}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(step.body),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          if (user != null)
            CustomButton(
              label: 'Replay first-time tour',
              icon: Icons.play_circle_outline,
              variant: CustomButtonVariant.outlined,
              onPressed: () async {
                await OnboardingService.reset(
                  userId: user.id,
                  role: user.role,
                );
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
              },
            ),
        ],
      ),
    );
  }
}
