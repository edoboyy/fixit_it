import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_model.dart';

/// Remembers whether each account has finished the first-time tour.
class OnboardingService {
  OnboardingService._();

  static String _key(String userId, UserRole role) =>
      'onboarding_done_${role.name}_$userId';

  static Future<bool> hasCompleted({
    required String userId,
    required UserRole role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId, role)) ?? false;
  }

  static Future<void> markCompleted({
    required String userId,
    required UserRole role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId, role), true);
  }

  static Future<void> reset({
    required String userId,
    required UserRole role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId, role));
  }

  static Future<bool> shouldShowFor(UserModel? user) async {
    if (user == null) return false;
    final done = await hasCompleted(userId: user.id, role: user.role);
    return !done;
  }
}
