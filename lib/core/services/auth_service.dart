import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase/supabase_service.dart';

class AuthService {
  AuthService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  final SupabaseService _supabaseService;

  GoTrueClient get _auth => _supabaseService.client.auth;

  Stream<AuthState> get authStateChanges {
    if (!_supabaseService.isInitialized) {
      return const Stream<AuthState>.empty();
    }
    return _auth.onAuthStateChange;
  }

  User? get currentUser {
    if (!_supabaseService.isInitialized) return null;
    return _auth.currentUser;
  }

  String? get currentUserId => currentUser?.id;

  bool get isLoggedIn => currentUser != null;

  bool checkLoginStatus() => isLoggedIn;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    _ensureInitialized();
    return _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
  }) async {
    _ensureInitialized();
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
    );

    // Ensure we have a session so profile inserts are authenticated.
    if (response.session == null && response.user != null) {
      return _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    }

    return response;
  }

  Future<void> logout() async {
    _ensureInitialized();
    await _auth.signOut();
  }

  Future<void> resetPassword({required String email}) async {
    _ensureInitialized();
    await _auth.resetPasswordForEmail(email.trim());
  }

  void _ensureInitialized() {
    if (!_supabaseService.isInitialized) {
      throw StateError(
        'Supabase is not set up. Paste your URL and anon key in '
        'lib/supabase/supabase_config.dart and run supabase/schema.sql.',
      );
    }
  }
}
