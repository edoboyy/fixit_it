import 'package:flutter/material.dart';

import '../models/artisan_model.dart';
import '../models/user_model.dart';
import '../screens/admin/artisans_screen.dart';
import '../screens/admin/bookings_screen.dart';
import '../screens/admin/dashboard.dart';
import '../screens/admin/payments_screen.dart';
import '../screens/admin/users_screen.dart';
import '../screens/artisan/artisan_shell.dart';
import '../screens/auth/forgot_password.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/customer/artisan_profile_screen.dart';
import '../screens/customer/booking_history.dart';
import '../screens/customer/booking_screen.dart';
import '../screens/customer/home_screen.dart';
import '../screens/customer/profile_screen.dart';
import '../screens/customer/search_screen.dart';
import '../screens/shared/how_to_use_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../widgets/error_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);
      case AppRoutes.welcome:
        return _page(const WelcomeScreen(), settings);
      case AppRoutes.login:
        final loginRole = settings.arguments is UserRole
            ? settings.arguments as UserRole
            : null;
        return _page(LoginScreen(initialRole: loginRole), settings);
      case AppRoutes.register:
        final registerRole = settings.arguments is UserRole
            ? settings.arguments as UserRole
            : UserRole.customer;
        return _page(RegisterScreen(initialRole: registerRole), settings);
      case AppRoutes.forgotPassword:
        return _page(const ForgotPasswordScreen(), settings);
      case AppRoutes.customerHome:
        return _page(const HomeScreen(), settings);
      case AppRoutes.customerSearch:
        return _page(const SearchScreen(), settings);
      case AppRoutes.customerArtisanProfile:
        final artisan = settings.arguments as ArtisanModel?;
        if (artisan == null) {
          return _page(const HomeScreen(), settings);
        }
        return _page(CustomerArtisanProfileScreen(artisan: artisan), settings);
      case AppRoutes.customerBooking:
        final artisan = settings.arguments as ArtisanModel?;
        if (artisan == null) {
          return _page(const HomeScreen(), settings);
        }
        return _page(BookingScreen(artisan: artisan), settings);
      case AppRoutes.customerBookingHistory:
        return _page(const BookingHistoryScreen(), settings);
      case AppRoutes.customerProfile:
        return _page(const ProfileScreen(), settings);
      case AppRoutes.artisanHome:
        return _page(const ArtisanShell(initialIndex: 0), settings);
      case AppRoutes.artisanBookingRequests:
        return _page(const ArtisanShell(initialIndex: 1), settings);
      case AppRoutes.artisanProfile:
        return _page(const ArtisanShell(initialIndex: 2), settings);
      case AppRoutes.artisanEarnings:
        return _page(const ArtisanShell(initialIndex: 3), settings);
      case AppRoutes.adminDashboard:
        return _page(const AdminDashboardScreen(), settings);
      case AppRoutes.adminUsers:
        return _page(const AdminUsersScreen(), settings);
      case AppRoutes.adminArtisans:
        return _page(const AdminArtisansScreen(), settings);
      case AppRoutes.adminBookings:
        return _page(const AdminBookingsScreen(), settings);
      case AppRoutes.adminPayments:
        return _page(const AdminPaymentsScreen(), settings);
      case AppRoutes.notifications:
        return _page(const NotificationsScreen(), settings);
      case AppRoutes.onboarding:
        return _page(const OnboardingScreen(), settings);
      case AppRoutes.howToUse:
        return _page(const HowToUseScreen(), settings);
      default:
        return _page(const ErrorScreen(), settings);
    }
  }

  static PageRouteBuilder<dynamic> _page(
    Widget child,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<dynamic>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.02, 0.01),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
