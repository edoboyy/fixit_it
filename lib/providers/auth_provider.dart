import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../core/services/storage_service.dart';
import '../models/artisan_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    FirestoreService? firestoreService,
    StorageService? storageService,
  })  : _authService = authService ?? AuthService(),
        _firestoreService = firestoreService ?? FirestoreService(),
        _storageService = storageService ?? StorageService() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthService _authService;
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  User? _authUser;
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isCheckingAuth = false;
  String? _errorMessage;

  User? get authUser => _authUser;

  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _authUser != null;

  bool get isLoading => _isLoading;

  bool get isCheckingAuth => _isCheckingAuth;

  String? get errorMessage => _errorMessage;

  Future<void> checkLoginStatus() async {
    _isCheckingAuth = true;
    notifyListeners();

    _authUser = _authService.currentUser;

    if (_authUser != null) {
      try {
        _currentUser = await _firestoreService.getUser(_authUser!.id);
        if (_currentUser?.isSuspended == true) {
          await _authService.logout();
          _currentUser = null;
          _authUser = null;
        }
      } catch (_) {
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }

    _isCheckingAuth = false;
    notifyListeners();
  }

  String get destinationRoute {
    if (!_authService.checkLoginStatus() || _currentUser == null) {
      return AppRoutes.welcome;
    }

    final role = _currentUser!.role;

    return switch (role) {
      UserRole.customer => AppRoutes.customerHome,
      UserRole.artisan => AppRoutes.artisanHome,
      UserRole.admin => AppRoutes.adminDashboard,
    };
  }

  Future<void> _onAuthStateChanged(AuthState state) async {
    final user = state.session?.user;
    _authUser = user;

    // Only clear the profile on a real sign-out. Token refresh / transient
    // auth events must not wipe currentUser or artisan screens think you
    // are logged out and reload an empty booking list.
    if (user == null) {
      if (state.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
      return;
    }

    // Already have this profile — keep it during refresh events.
    if (_currentUser?.id == user.id) {
      notifyListeners();
      return;
    }

    try {
      final profile = await _firestoreService.getUser(user.id);
      if (profile != null) {
        _currentUser = profile;
      }
      // If profile fetch fails/returns null, keep any existing matching user.
    } catch (_) {
      // Keep existing profile on transient errors.
    }

    notifyListeners();
  }

  Future<bool> login({
    required String emailOrUsername,
    required String password,
    UserRole? expectedRole,
  }) {
    return _runAuthAction(() async {
      final profile = await _firestoreService.findUserByEmailOrName(
        emailOrUsername,
      );

      if (profile == null) {
        throw const AuthException(
          'No account found with that email or username.',
        );
      }

      if (expectedRole != null && profile.role != expectedRole) {
        throw AuthException(
          'This account is registered as a ${profile.role.value}. '
          'Please sign in from the ${profile.role.value} option.',
        );
      }

      await _authService.login(email: profile.email, password: password);
      final userId = _authService.currentUserId;
      if (userId != null) {
        try {
          _currentUser = await _firestoreService.getUser(userId);
        } catch (_) {
          _currentUser = null;
        }
      }

      if (_currentUser == null) {
        await _authService.logout();
        throw const AuthException(
          'Login succeeded but profile could not be loaded. Try again.',
        );
      }

      if (_currentUser!.isSuspended) {
        await _authService.logout();
        _currentUser = null;
        throw const AuthException('This account has been suspended.');
      }
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required UserRole role,
    String? profession,
    String? experience,
    String? nationalId,
    String? idType,
    String? location,
    Uint8List? certificateBytes,
    String? certificateFileName,
  }) {
    return _runAuthAction(() async {
      if (role == UserRole.admin) {
        throw const AuthException(
          'Admin accounts cannot be self-registered.',
        );
      }

      final response = await _authService.register(
        email: email,
        password: password,
      );

      final user = response.user ?? _authService.currentUser;
      if (user == null) {
        throw const AuthException(
          'Registration failed. In Supabase Auth settings, turn OFF "Confirm email".',
        );
      }

      _authUser = user;

      await _firestoreService.saveUser(
        UserModel(
          id: user.id,
          name: name,
          email: email,
          phone: phone,
          role: role,
          location: location,
          password: password,
        ),
      );

      if (role == UserRole.artisan) {
        String? certificateUrl;

        if (certificateBytes != null && certificateFileName != null) {
          certificateUrl = await _storageService.uploadArtisanCertificate(
            artisanId: user.id,
            fileBytes: certificateBytes,
            fileName: certificateFileName,
          );
        }

        final idNumber = nationalId?.trim() ?? '';
        final type = idType?.trim();
        final storedId = type == null || type.isEmpty
            ? idNumber
            : '$type|$idNumber';

        await _firestoreService.saveArtisan(
          ArtisanModel(
            id: user.id,
            userId: user.id,
            name: name,
            email: email,
            phone: phone,
            category: profession ?? '',
            experience: experience,
            nationalId: storedId,
            location: location,
            certificateUrl: certificateUrl,
            isVerified: false,
          ),
        );
      }

      _currentUser = await _firestoreService.getUser(user.id);
      if (_currentUser == null) {
        throw const AuthException(
          'Account auth was created but profile save failed. '
          'Run supabase/fix_rls.sql in the SQL Editor, then try logging in.',
        );
      }
    });
  }

  Future<bool> logout() {
    return _runAuthAction(() async {
      await _authService.logout();
      _currentUser = null;
      _authUser = null;
    });
  }

  Future<bool> resetPassword({required String email}) {
    return _runAuthAction(() async {
      await _authService.resetPassword(email: email);
    });
  }

  Future<bool> updateProfile(UserModel user) {
    return _runAuthAction(() async {
      await _firestoreService.updateUser(user);
      _currentUser = user;
    });
  }

  Future<void> refreshCurrentUser() async {
    final userId = _authUser?.id;
    if (userId == null) return;

    _currentUser = await _firestoreService.getUser(userId);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e);
      return false;
    } on PostgrestException catch (e) {
      _errorMessage = e.code == '42501'
          ? 'Database permission error. Run supabase/fix_rls.sql in the Supabase SQL Editor, then try again.'
          : e.message;
      return false;
    } on StateError catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login') ||
        message.contains('invalid credentials') ||
        message.contains('invalid email or password')) {
      return 'Incorrect email/username or password.';
    }
    if (message.contains('no account found')) {
      return e.message;
    }
    if (message.contains('registered as')) {
      return e.message;
    }
    if (message.contains('already registered') ||
        message.contains('already been registered')) {
      return 'An account already exists with this email.';
    }
    if (message.contains('password') && message.contains('weak')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (message.contains('suspended')) {
      return 'This account has been suspended or disabled.';
    }
    if (message.contains('network') || message.contains('socket')) {
      return 'Network error. Check your connection and try again.';
    }
    if (message.contains('email not confirmed')) {
      return 'Email not confirmed. Turn OFF "Confirm email" in Supabase Auth settings.';
    }
    return e.message;
  }
}
