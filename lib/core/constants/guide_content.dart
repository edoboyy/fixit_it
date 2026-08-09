import 'package:flutter/material.dart';

import '../../models/user_model.dart';

class GuidePage {
  const GuidePage({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;
}

/// First-time tour + “How to use” copy for each account type.
class GuideContent {
  GuideContent._();

  static List<GuidePage> onboardingPages(UserRole role) {
    return switch (role) {
      UserRole.customer => const [
          GuidePage(
            title: 'Find trusted artisans',
            body:
                'Browse categories like Plumbing, Electrical, and Carpentry. '
                'Search by name, skill, or location across Ghana.',
            icon: Icons.search_rounded,
          ),
          GuidePage(
            title: 'Book a job',
            body:
                'Open an artisan’s profile, pick a date and place, then send '
                'your booking. An admin reviews it before the artisan sees it.',
            icon: Icons.calendar_month_rounded,
          ),
          GuidePage(
            title: 'Track → Confirm & Pay',
            body:
                'Follow status updates from Accept to Done. When work is '
                'finished, tap Confirm & Pay (simulated payment), then leave '
                'a review.',
            icon: Icons.payments_rounded,
          ),
        ],
      UserRole.artisan => const [
          GuidePage(
            title: 'Complete your profile',
            body:
                'Set your skill category, location, rate, and availability. '
                'Admins verify artisan accounts so customers can trust you.',
            icon: Icons.badge_outlined,
          ),
          GuidePage(
            title: 'Receive job requests',
            body:
                'After admin approves a booking, it appears under Requests. '
                'Accept or reject, then work the job step by step.',
            icon: Icons.inbox_outlined,
          ),
          GuidePage(
            title: 'Work → Get paid',
            body:
                'Flow: Accept → On my way → Start work → Mark done. '
                'When the customer confirms payment, earnings show up here.',
            icon: Icons.handyman_rounded,
          ),
        ],
      UserRole.admin => const [
          GuidePage(
            title: 'Oversee the platform',
            body:
                'Your dashboard shows users, artisans, bookings, payments, '
                'and revenue at a glance.',
            icon: Icons.dashboard_customize_outlined,
          ),
          GuidePage(
            title: 'Verify artisans',
            body:
                'Review certificates and IDs under Artisans. Verifying builds '
                'trust — it does not send jobs by itself.',
            icon: Icons.verified_user_outlined,
          ),
          GuidePage(
            title: 'Approve bookings',
            body:
                'Under Bookings, approve waiting jobs so artisans receive '
                'them. Reject invalid requests when needed.',
            icon: Icons.fact_check_outlined,
          ),
        ],
    };
  }

  static String roleHeadline(UserRole role) {
    return switch (role) {
      UserRole.customer => 'Book home services with confidence',
      UserRole.artisan => 'Grow your craft business on Fixit GH',
      UserRole.admin => 'Keep Fixit GH running smoothly',
    };
  }

  static String roleSummary(UserRole role) {
    return switch (role) {
      UserRole.customer =>
        'Discover verified artisans near you, book a visit, track the job, '
        'then Confirm & Pay when the work is done.',
      UserRole.artisan =>
        'Keep your profile ready, accept approved requests, update job '
        'status as you work, and collect earnings after payment.',
      UserRole.admin =>
        'Verify artisans, approve bookings for artisans, monitor users and '
        'payments, and keep the marketplace healthy.',
    };
  }

  static List<GuidePage> howToSteps(UserRole role) => onboardingPages(role);
}
