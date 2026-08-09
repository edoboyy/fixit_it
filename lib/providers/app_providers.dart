import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'artisan_provider.dart';
import 'admin_provider.dart';
import 'auth_provider.dart';
import 'booking_provider.dart';
import 'earnings_provider.dart';
import 'notification_provider.dart';
import 'theme_provider.dart';

class AppProviders {
  AppProviders._();

  static List<SingleChildWidget> get providers => [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => ArtisanProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ];
}
