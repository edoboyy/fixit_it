class AppRoutes {
  AppRoutes._();

  // Splash
  static const String splash = '/';

  // Auth
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Customer
  static const String customerHome = '/customer/home';
  static const String customerSearch = '/customer/search';
  static const String customerArtisanProfile = '/customer/artisan';
  static const String customerBooking = '/customer/booking';
  static const String customerBookingHistory = '/customer/booking-history';
  static const String customerProfile = '/customer/profile';

  // Artisan
  static const String artisanHome = '/artisan/home';
  static const String artisanBookingRequests = '/artisan/booking-requests';
  static const String artisanEarnings = '/artisan/earnings';
  static const String artisanProfile = '/artisan/profile';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminArtisans = '/admin/artisans';
  static const String adminBookings = '/admin/bookings';
  static const String adminPayments = '/admin/payments';

  // Shared
  static const String notifications = '/notifications';
  static const String onboarding = '/onboarding';
  static const String howToUse = '/how-to-use';
}
